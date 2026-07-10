# Database philosophy

How we model data in Stan. These rules apply to every table. The concrete schema (ERD, entities, Prisma models) is designed and validated in **Phase 1**; this document is the constitution that Phase 1 must obey.

Decision record: [ADR-0003](adr/ADR-0003-database-conventions.md).

---

## 1. Principles

1. **Redesign, don't port.** The legacy PHP/SQL schema is a functional reference only. We normalize from first principles and never reproduce its municipality-specific baggage. (Context.md, *Database Philosophy*.)
2. **Data-driven everything.** No municipality name, structure, program, schedule, role, school zone, email domain or CAF value is ever hardcoded — it is a row someone can edit. If a value could differ between two municipalities, it is data.
3. **Normalize by default.** 3NF as the baseline. Denormalize only with a measured performance reason, documented in an ADR, and kept consistent by the application layer or triggers.
4. **Every row belongs to a tenant** (unless deliberately global). See [multi-tenancy.md](multi-tenancy.md).
5. **Nothing is truly lost.** Soft delete + audit trail for business data. History is preserved.
6. **The database enforces its own integrity.** Foreign keys, `NOT NULL`, `UNIQUE`, `CHECK` constraints, and RLS are not optional — the DB is the last line of defense, not just a bucket.

---

## 2. Base columns (every business table)

Every business table includes, at minimum:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | PK, default `gen_random_uuid()`. Opaque, non-sequential (no enumeration leaks). |
| `created_at` | `timestamptz` | default `now()`. |
| `updated_at` | `timestamptz` | maintained by app + `@updatedAt`. |

**When tenant-scoped (almost always):**

| Column | Type | Notes |
| --- | --- | --- |
| `municipality_id` | `uuid` | FK → `municipalities.id`, `NOT NULL`, indexed. Basis of isolation. |

**When the record is user-authored (most operational data):**

| Column | Type | Notes |
| --- | --- | --- |
| `created_by` | `uuid` | FK → `users.id`, nullable (system-created rows). |
| `updated_by` | `uuid` | FK → `users.id`, nullable. |

**When soft-deletable (business/operational data — see §5):**

| Column | Type | Notes |
| --- | --- | --- |
| `deleted_at` | `timestamptz` | null = live. Non-null = deleted. |
| `deleted_by` | `uuid` | FK → `users.id`, nullable. |

Pure lookup/config tables (e.g. permission catalog, school-zone enum) may omit `created_by/updated_by/deleted_at` where they add no value — decided per table in Phase 1.

---

## 3. Identifiers

- **Primary keys are `uuid`** (`gen_random_uuid()`). Rationale: no cross-tenant enumeration, safe in URLs, generated without a round-trip, and compatible with Supabase Auth (which uses `uuid`).
- If insertion-order locality becomes a measured index-bloat problem, we migrate to **UUID v7** (time-ordered) — a drop-in `uuid` replacement — rather than to sequential integers, which would leak counts across tenants.
- **Natural keys** (SIRET, national identifiers) are stored as attributes with appropriate uniqueness constraints, never as primary keys.

---

## 4. Naming conventions

- **Tables:** `snake_case`, **plural** (`children`, `attendance_records`, `opening_hours`).
- **Columns:** `snake_case`, singular (`first_name`, `municipality_id`, `starts_at`).
- **Foreign keys:** `<referenced_singular>_id` (`family_id`, `structure_id`).
- **Join tables:** `<a>_<b>` alphabetical (`role_permissions`).
- **Booleans:** prefixed `is_`/`has_`/`can_` (`is_active`, `has_pai`).
- **Timestamps:** `*_at` (`starts_at`, `checked_in_at`). **Dates:** `*_date` / `*_on` where time is irrelevant.
- **Enums:** Postgres enums for closed, stable sets that are *not* tenant-configurable (e.g. `membership_status`). Anything a municipality might extend is a **lookup table**, not an enum.
- **Prisma models:** `PascalCase` singular (`AttendanceRecord`) mapped to snake_case plural tables via `@@map` / `@map`. This keeps idiomatic TS and idiomatic SQL simultaneously.

---

## 5. Soft delete

- **Business & operational data** (families, children, activities, attendance, documents…) is **soft-deleted**: set `deleted_at`, never physically removed by the app. Rationale: municipal records have legal/operational retention needs; accidental deletion must be recoverable; audit continuity.
- The **tenant-scoped Prisma extension automatically excludes** `deleted_at IS NOT NULL` from default reads, so "deleted" rows disappear from the app without every query remembering to filter. Explicit "include trashed" reads are an opt-in method for restore/admin views.
- **Hard delete** is reserved for: (a) GDPR erasure requests, executed by a dedicated, audited erasure service; (b) purging expired soft-deleted rows per the retention policy; (c) truly transient rows with no business meaning. Never casual.
- Uniqueness constraints account for soft delete (e.g. a partial unique index `WHERE deleted_at IS NULL`) so a deleted record doesn't block re-creating a valid one.

See [security.md](security.md) for GDPR erasure and retention.

---

## 6. Constraints & integrity

- **Foreign keys** on every relationship, with explicit `ON DELETE` behaviour (default `RESTRICT`; `CASCADE` only where the child has no independent existence, e.g. a role's permissions).
- **`NOT NULL`** is the default; nullability is a deliberate, documented choice.
- **`CHECK`** constraints encode invariants the DB can guarantee (`ends_at > starts_at`, `capacity >= 0`, valid ranges).
- **`UNIQUE`** constraints (often composite with `municipality_id`) prevent duplicates *within a tenant* (e.g. `UNIQUE (municipality_id, code)` for a structure code).
- **RLS** on every tenant table (see [multi-tenancy.md](multi-tenancy.md)).

---

## 7. Indexing

- Index every **foreign key** (Postgres does not do this automatically).
- Index `municipality_id` on every tenant table, and use **composite indexes leading with `municipality_id`** for common access paths (`(municipality_id, structure_id, date)` for attendance lookups), because virtually every query is tenant-filtered first.
- Partial indexes for soft delete (`WHERE deleted_at IS NULL`) on hot tables.
- Indexes are added with the query that needs them and justified in the PR; we don't speculatively over-index.

---

## 8. Temporal & configuration data

Municipal configuration is **time-bound and versioned**, not overwritten in place, wherever history matters:

- **School calendars, holiday periods, opening hours, pricing** are stored with validity ranges (`valid_from`, `valid_to`) or bound to a **school year**, so we can answer "what were the opening hours in October 2024?" and so editing next year's pricing never rewrites this year's records.
- A **school year** is a first-class entity; most operational data references the year it belongs to.
- This temporal discipline is what lets the same tenant evolve its configuration across years without corrupting historical statistics and CAF reporting.

---

## 9. Money, dates, personal data

- **Money** stored as integer minor units (cents) or `numeric(12,2)` — never floating point. Currency is EUR but stored explicitly for future-proofing.
- **Dates/times** stored `timestamptz`; the application owns timezone presentation (Europe/Paris by default, per-municipality configurable).
- **Personal data (PII)** of children, families and agents is classified in Phase 1 (see [security.md](security.md)): fields are tagged for GDPR export/erasure, sensitive fields (health/PAI, handicap follow-up) get stricter access controls and are candidates for column-level encryption.

---

## 10. Prisma usage rules

- Schema owned by `@stan/db`; one source of truth.
- Migrations are **generated, reviewed, and committed** — never `db push` against anything but a throwaway local DB. Production changes go through reviewed SQL migrations. See [deployment.md](deployment.md).
- Repositories are the only Prisma consumers; they use the **tenant-scoped client**.
- No business logic in Prisma middleware except the cross-cutting tenant/soft-delete/audit concerns provided centrally by `@stan/core`.

---

## 11. What Phase 1 will deliver (preview)

Phase 1 (database design) produces, for validation before any code:
- a complete **ERD**;
- an **entity dictionary** — every table, why it exists, its columns, and its relationships explained;
- **relationships, indexes, constraints** in full;
- a **Prisma schema proposal**;
- a self-critique: simplifications found, and every design decision challenged.

This document is the rulebook that work will be judged against.
