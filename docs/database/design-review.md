# Design review — conventions, simplifications, self-critique, open decisions

This is where I challenge my own design (Context.md: *Look for simplifications. Challenge your own design.*). It records the conventions applied, the simplifications I made and rejected, the engineering decisions I took (and why), the risks I see, and the **open decisions I need you to confirm** before this becomes a migration.

---

## 1. Conventions applied

All from [database-philosophy.md](../database-philosophy.md), applied uniformly:
- UUID PKs (`gen_random_uuid()`), `created_at`/`updated_at` everywhere, `deleted_at`/`deleted_by` on soft-deletable tables, `municipality_id` on every tenant table.
- snake_case plural tables, snake_case columns, PascalCase Prisma models via `@@map`/`@map`.
- Money as integer cents; dates as `date`, times as `time`, timestamps as `timestamptz`.
- Enums for fixed closed sets; lookup tables where tenants extend values.
- Temporal/validity-bound config (school years, opening hours, pricing) to preserve history.
- FKs, `NOT NULL` defaults, `CHECK`, and partial unique indexes — several expressed in **migration SQL** (noted inline in `schema.prisma`) because Prisma can't declare partial-unique/`CHECK`/RLS.

---

## 2. Engineering decisions I made (open to override, but I recommend keeping)

These are my calls as CTO; I'll change them if you disagree, but here's the reasoning.

**(E1) `municipality_id` is a scalar column, not a Prisma relation.**
Modelling it as a relation would add ~35 back-relations to `Municipality`, turning it into an unreadable hub, for no real benefit: we never navigate `municipality.children` — we query children *scoped by* `municipalityId` through the tenant extension. The FK is still enforced in migration SQL. Trade-off: no Prisma-level cascade from municipality (acceptable — tenants are soft-deactivated, not hard-deleted; a deliberate purge is a dedicated audited job).

**(E2) `created_by`/`updated_by`/`deleted_by` are scalar UUIDs, not relations to `User`.**
Same reasoning: these audit-actor columns appear on almost every table; relations would put dozens of back-references on `User`. FKs enforced in migration SQL. The audit *trail* (who/what/when) lives in `audit_logs`; these columns are convenience attribution.

**(E3) One immutable `audit_logs` table, DB-role-restricted to INSERT/SELECT.**
Append-only by privilege, not just convention. See [audit.md](../audit.md).

**(E4) `settings`, `municipality_modules`, `email_domains` as small tables, not JSON columns on `municipalities`.**
Queryable, auditable, constrainable. Structured config is always tables; the `settings` key/value table absorbs only the genuinely free-form remainder (Zod-typed values).

**(E5) Guardians are data, not users (for now).**
A parent-portal login is a future app (see [ADR-0001](../adr/ADR-0001-modular-monolith-monorepo.md)); when it arrives, a guardian gains an optional `user_id` link. No rework of the core needed.

---

## 3. Simplifications — found and rejected

**Adopted:**
- **Unified `children`** for childhood *and* youth (one subject, not two near-identical tables). ↔ open decision **D1**.
- **Inline addresses** on `families`/`structures` + a normalized `neighborhoods` reference — instead of a full normalized `addresses`/`streets` graph. Municipal addresses are rarely queried relationally; neighborhood is the dimension that matters for stats/GIS. ↔ open decision **D3**.
- **Polymorphic `documents`** (`owner_type` + `owner_id`) instead of one document table per owner. ↔ open decision **D4**.
- **`caf_indicators` only** now; CAF *declarations/aggregates* are computed in Phase 5 over operational data (a `caf_declarations` snapshot table is added then, not speculatively now).

**Rejected (kept the fuller design):**
- Collapsing `enrollments` into `attendance` — rejected; enrollment (registration intent) and attendance (actual presence) are distinct and both needed for billing and stats.
- Collapsing `sessions` into `programs` — rejected; a program is the offer, a session is a dated occurrence; attendance needs the occurrence.
- A single generic `people` table for guardians + children — rejected; their attributes and lifecycles differ enough that one table would be mostly-null columns.

---

## 4. Open decisions — I need your call (they're expensive to change after migration)

| # | Decision | My recommendation | Why it's yours to make |
| --- | --- | --- | --- |
| **D1** | **Child vs Youth**: one `children` entity for all young beneficiaries, or two separate entities? | **Unify** into one entity (a person served across the childhood→youth span; "youth" is expressed via age + which programs they're enrolled in). Optionally rename `children` → a neutral term. | Depends on whether your municipal processes treat *enfance* and *jeunesse* as the same person record or genuinely separate files. |
| **D2** | **Configurable structure/program types**: fixed enums (`SCHOOL/LEISURE/YOUTH/HOLIDAY`, `ACTIVITY/WORKSHOP`) or tenant-editable **lookup tables**? | **Keep enums** for now (simpler, indexable) — migrate to lookup tables only if municipalities need their own types. | "No hardcoded data" could imply municipalities invent structure types. If any customer needs that, these must be lookup tables from day one. |
| **D3** | **Streets** (Context.md lists Streets as configurable): add a `streets` config table referenced by addresses, or keep addresses free-text with only `neighborhoods` normalized? | **Neighborhoods normalized, streets free-text** (add a `streets` table later only if a workflow needs street-level dropdowns/stats). | Whether street-level normalization delivers real value for your reporting, or is over-engineering. |
| **D4** | **Documents ownership**: polymorphic (`owner_type`+`owner_id`) or explicit nullable FK columns per owner type? | **Polymorphic** (flexible, one table) with app-enforced integrity + a `CHECK` on `owner_type`. | Polymorphic trades DB-level FK integrity for flexibility; explicit FKs give integrity but a wider table. Your call on the trade-off. |
| **D5** | **Attendance without enrollment**: allow recording attendance for a child not formally enrolled in that program (drop-in), or require an enrolment? | **Allow drop-in** (record against session+child; enrolment optional) — municipal reality often includes unregistered presence. | Reflects your operational rules; changes a constraint. |

### ✅ Resolved (validated 2026-07-10)

All five decisions are settled; the schema already reflects them — no rework needed.

| # | Outcome |
| --- | --- |
| **D1** | **Unify** — one `children` entity for childhood *and* youth. |
| **D2** | **Fixed enums** for structure/program types (migrate to lookup tables only if a customer needs custom types). |
| **D3** | **Neighborhoods normalized, streets free-text** (no `streets` table for now). |
| **D4** | **Polymorphic `documents`** (owner_type + owner_id), app-enforced integrity + `CHECK` on `owner_type`. *(default)* |
| **D5** | **Allow drop-in attendance** — attendance recorded against session + child; enrolment optional. *(default)* |

---

## 5. Self-critique / known risks

- **Polymorphic `documents` (D4)** loses referential integrity at the DB level — a `document.owner_id` can point at a deleted row. Mitigation: app-layer checks + periodic integrity job; or switch to typed FKs if you pick that in D4.
- **Scalar `municipality_id` (E1)** means municipality cascades/joins are DB-SQL concerns, not Prisma-native. Acceptable given the tenant extension is the access path, but reviewers used to relation-based Prisma should read E1 first.
- **`@db.Time` for opening/session hours** stores wall-clock time without a date; DST and timezone are handled by the app (municipality timezone). Fine for opening hours; if we ever need cross-midnight sessions, revisit.
- **`meals` is thin** — real meal management likely needs menus, allergen linkage to `pais`, and headcount forecasting. Deliberately deferred to Phase 4; the current table is a placeholder-quality *design*, not code.
- **Pricing is quotient-range based** — French CAF pricing can be grid/formula-based; `pricing_tiers` may need a richer rule model. Flagged for the CAF phase.
- **No billing/invoicing tables** — pricing exists, invoicing is out of MVP scope; a `billing` domain is a future addition, not forgotten.
- **`citext` and `gen_random_uuid()`** require Postgres extensions/PG13+ — enabled in the first migration (Supabase supports both).
- **RLS is not visible in `schema.prisma`** — it's added per-table in migration SQL. A CI check (see [ci-cd.md](../ci-cd.md)) asserts every tenant table has RLS; don't rely on reading the Prisma file to confirm isolation.

---

## 6. What Phase 2 does with this

On your validation:
1. Move `schema.prisma` to `packages/db`, add the migration SQL for partial-unique indexes, `CHECK`s, FKs on scalar columns, **RLS policies**, and extension enablement.
2. Generate the first migration; wire the tenant-scoped client extension + soft-delete filter.
3. Seed the global `permissions` catalog and an optional role template.
4. Ship the isolation + RLS tests ([testing.md](../testing.md)) as the first tests in the repo.

No application/business code until this schema is validated.
