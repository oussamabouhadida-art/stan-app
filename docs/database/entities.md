# Entity dictionary

Every table, why it exists, its columns, relationships, indexes, and constraints. Grouped by the four layers. **Base columns** (below) are implied on every table and not repeated in each list.

**Base columns (per [database-philosophy.md](../database-philosophy.md)):**
- `id uuid PK` (default `gen_random_uuid()`) — all tables.
- `created_at`, `updated_at timestamptz` — all tables.
- `municipality_id uuid` — all **tenant-scoped** tables (FK → `municipalities.id`, `NOT NULL`, indexed, RLS key). Stored as a scalar FK, not a Prisma relation — see [design-review.md](design-review.md) §2.
- `created_by`, `updated_by uuid` — user-authored tables (→ `users.id`, nullable).
- `deleted_at timestamptz`, `deleted_by uuid` — **soft-deletable** tables (marked 🗑 below).

Legend: 🏛 global (not tenant-scoped) · 🗑 soft-deletable · 🔒 contains sensitive (Art. 9) data.

---

# Layer 1 — Foundation

## `communities` 🏛
**Why:** groups municipalities (communauté de communes / agglomération) for cross-tenant reporting and shared staff. Not an isolation boundary — isolation is always at the municipality.
| Column | Type | Notes |
| --- | --- | --- |
| `name` | text | |
| `code` | text | unique |
- **Relationships:** `communities 1—* municipalities`.
- **Indexes/constraints:** `UNIQUE(code)`.

## `municipalities` 🗑
**Why:** the **tenant root**. Every business row ultimately belongs to one municipality. Holds identity, branding, locale/timezone.
| Column | Type | Notes |
| --- | --- | --- |
| `code` | text | stable natural key (e.g. INSEE); unique |
| `name` | text | |
| `community_id` | uuid | FK → communities, nullable |
| `siret` | text | nullable, validated |
| `timezone` | text | default `Europe/Paris` |
| `locale` | text | default `fr-FR` |
| `address_street` / `address_postal_code` / `address_city` | text | inline identity address |
| `contact_email` / `contact_phone` | text | |
| `logo_url` / `primary_color` / `secondary_color` / `banner` | text | branding → runtime theme |
| `status` | enum `municipality_status` | `ACTIVE \| SUSPENDED` |
- **Relationships:** belongs to `communities`; parent of all tenant tables.
- **Indexes/constraints:** `UNIQUE(code)`; index `community_id`. Soft delete = deactivate tenant (retains data).
- **Note:** `municipalities` is itself the tenant; it is **not** filtered by the tenant extension (it *is* the scope). Access is controlled by membership + super-admin.

## `users` 🏛
**Why:** global identity, **1:1 with the Supabase auth user** (`id` = auth `uid`). Holds profile only; **no credentials** (those live in Supabase). Global because one person may serve several municipalities.
| Column | Type | Notes |
| --- | --- | --- |
| `email` | citext | unique |
| `first_name` / `last_name` | text | |
| `locale` | text | default `fr-FR` |
| `is_super_admin` | boolean | default false; platform operator |
| `status` | enum `user_status` | `ACTIVE \| DISABLED` |
- **Relationships:** `users 1—* memberships`; referenced by `*_by` audit columns everywhere.
- **Indexes/constraints:** `UNIQUE(email)`.

## `memberships` 🗑
**Why:** the link that makes a user a member of a municipality **with a role**. A user has many (one per municipality); this is what enables the confirmed multi-municipality model.
| Column | Type | Notes |
| --- | --- | --- |
| `user_id` | uuid | FK → users |
| `municipality_id` | uuid | FK → municipalities |
| `role_id` | uuid | FK → roles |
| `status` | enum `membership_status` | `INVITED \| ACTIVE \| SUSPENDED` |
| `invited_at` / `accepted_at` | timestamptz | nullable |
- **Relationships:** ties `users`, `municipalities`, `roles`; parent of `membership_structures`.
- **Indexes/constraints:** partial `UNIQUE(user_id, municipality_id) WHERE deleted_at IS NULL` (one live membership per municipality); index `municipality_id`, `role_id`.

## `roles` 🗑
**Why:** a **per-municipality**, editable bundle of permissions (Context.md: no hardcoded roles). Two municipalities may have entirely different roles.
| Column | Type | Notes |
| --- | --- | --- |
| `name` | text | |
| `description` | text | nullable |
| `is_template` | boolean | seeded starting point; still editable |
- **Relationships:** `roles 1—* memberships`; `roles *—* permissions` via `role_permissions`.
- **Indexes/constraints:** `UNIQUE(municipality_id, name) WHERE deleted_at IS NULL`.

## `permissions` 🏛
**Why:** the **global catalog** of atomic capabilities (`domain.action`). Code checks these keys, never role names. Global so the vocabulary is consistent across all tenants.
| Column | Type | Notes |
| --- | --- | --- |
| `key` | text | unique, e.g. `attendance.write` |
| `domain` | text | e.g. `attendance` |
| `description` | text | |
- **Relationships:** `permissions *—* roles` via `role_permissions`.
- **Indexes/constraints:** `UNIQUE(key)`; index `domain`. Seeded from code; not tenant-editable.

## `role_permissions`
**Why:** the many-to-many mapping of which permissions a role grants.
| Column | Type | Notes |
| --- | --- | --- |
| `role_id` | uuid | FK → roles |
| `permission_id` | uuid | FK → permissions |
| `municipality_id` | uuid | denormalized for RLS/scoping |
- **Indexes/constraints:** `UNIQUE(role_id, permission_id)`; index `permission_id`. `ON DELETE CASCADE` from role.

## `membership_structures`
**Why:** optionally scopes a membership to specific structures (an animator assigned to one leisure centre). Backs `users[].structureCodes` on import and the future structure-scoped authorization layer.
| Column | Type | Notes |
| --- | --- | --- |
| `membership_id` | uuid | FK → memberships |
| `structure_id` | uuid | FK → structures |
- **Indexes/constraints:** `UNIQUE(membership_id, structure_id)`.

## `audit_logs`
**Why:** append-only "who did what, when, in which tenant" — security + GDPR accountability ([audit.md](../audit.md)). No `updated_at`/soft-delete; immutable.
| Column | Type | Notes |
| --- | --- | --- |
| `municipality_id` | uuid | nullable (platform-level events) |
| `actor_user_id` | uuid | nullable = `system` |
| `actor_membership_id` | uuid | role in effect, nullable |
| `action` | text | typed key, e.g. `config.pricing.update` |
| `entity_type` / `entity_id` | text / uuid | affected record |
| `summary` | text | human-readable |
| `metadata` | jsonb | before/after (PII-minimized), request id, ip, ua |
| `severity` | enum `audit_severity` | `INFO \| NOTICE \| SECURITY` |
- **Indexes/constraints:** index `(municipality_id, created_at)`, `(entity_type, entity_id)`, `actor_user_id`. App DB role has `INSERT`/`SELECT` only (no `UPDATE`/`DELETE`).

## `settings`
**Why:** typed key/value for tenant preferences that don't warrant a dedicated table (Zod-validated values). Structured config uses proper tables; this absorbs the remainder.
| Column | Type | Notes |
| --- | --- | --- |
| `key` | text | e.g. `attendance.allowRetroactiveDays` |
| `value` | jsonb | validated on write |
- **Indexes/constraints:** `UNIQUE(municipality_id, key)`.

## `municipality_modules`
**Why:** feature gating **as data** — which business domains are enabled for a tenant (Context.md: enabled modules). Queryable + auditable (vs a JSON blob).
| Column | Type | Notes |
| --- | --- | --- |
| `module_key` | text | e.g. `passport_jeune` |
| `enabled` | boolean | |
- **Indexes/constraints:** `UNIQUE(municipality_id, module_key)`.

## `email_domains`
**Why:** the allowed email domains for a municipality (Context.md).
| Column | Type | Notes |
| --- | --- | --- |
| `domain` | text | e.g. `ville-example.fr` |
- **Indexes/constraints:** `UNIQUE(municipality_id, domain)`.

---

# Layer 2 — Configuration / structural

## `neighborhoods` 🗑
**Why:** configurable neighborhoods for addressing, GIS, and statistics (Context.md: Neighborhoods). Referenced by families/structures rather than free-typed.
| Column | Type | Notes |
| --- | --- | --- |
| `name` | text | |
| `code` | text | nullable |
- **Indexes/constraints:** `UNIQUE(municipality_id, name) WHERE deleted_at IS NULL`.

## `structures` 🗑
**Why:** the physical/organizational units — schools, leisure/youth/holiday centres (Context.md). Host programs, sessions, opening hours; carry geo for GIS.
| Column | Type | Notes |
| --- | --- | --- |
| `code` | text | unique per municipality |
| `name` | text | |
| `type` | enum `structure_type` | `SCHOOL \| LEISURE \| YOUTH \| HOLIDAY` |
| `neighborhood_id` | uuid | FK → neighborhoods, nullable |
| `address_street` / `address_postal_code` / `address_city` | text | |
| `geo_lat` / `geo_lng` | decimal(9,6) | nullable (Leaflet) |
| `capacity` | int | `CHECK >= 0` |
- **Indexes/constraints:** `UNIQUE(municipality_id, code) WHERE deleted_at IS NULL`; index `type`, `neighborhood_id`.

## `school_years`
**Why:** the operational year most data binds to; carries the holiday zone. First-class so config and statistics stay historically accurate ([database-philosophy.md](../database-philosophy.md) §8).
| Column | Type | Notes |
| --- | --- | --- |
| `label` | text | e.g. `2025-2026` |
| `starts_on` / `ends_on` | date | |
| `zone` | enum `holiday_zone` | `A \| B \| C` |
- **Indexes/constraints:** `UNIQUE(municipality_id, label)`; `CHECK(ends_on > starts_on)`.

## `holiday_periods`
**Why:** school-holiday windows within a year (Toussaint, Noël…), driving extrascolaire planning.
| Column | Type | Notes |
| --- | --- | --- |
| `school_year_id` | uuid | FK → school_years |
| `name` | text | |
| `starts_on` / `ends_on` | date | must fall within the year (service-enforced) |
- **Indexes/constraints:** index `(school_year_id)`; `CHECK(ends_on >= starts_on)`.

## `public_holidays`
**Why:** public holidays (closures) per year.
| Column | Type | Notes |
| --- | --- | --- |
| `school_year_id` | uuid | FK, nullable (can be municipality-global) |
| `name` | text | |
| `date` | date | |
- **Indexes/constraints:** `UNIQUE(municipality_id, date, name)`.

## `opening_hours`
**Why:** per-structure opening windows, validity-bound so history is preserved when hours change.
| Column | Type | Notes |
| --- | --- | --- |
| `structure_id` | uuid | FK → structures |
| `period` | text | nullable (`periscolaire`/`vacances`/…) |
| `day_of_week` | enum `weekday` | `MONDAY..SUNDAY` |
| `opens_at` / `closes_at` | time | |
| `valid_from` / `valid_to` | date | nullable range |
- **Indexes/constraints:** index `(structure_id, day_of_week)`; `CHECK(closes_at > opens_at)`.

## `programs` 🗑
**Why:** the offer — activities and workshops children/youth enrol in (Context.md: Programs, Workshops, Activities). Bounded by age; optionally tied to a structure.
| Column | Type | Notes |
| --- | --- | --- |
| `code` | text | unique per municipality |
| `name` | text | |
| `type` | enum `program_type` | `ACTIVITY \| WORKSHOP` |
| `structure_id` | uuid | FK, nullable |
| `min_age` / `max_age` | int | nullable; `CHECK(max_age >= min_age)` |
| `capacity` | int | nullable, `CHECK >= 0` |
- **Indexes/constraints:** `UNIQUE(municipality_id, code) WHERE deleted_at IS NULL`; index `structure_id`, `type`.

## `pricing_tiers`
**Why:** pricing rules, commonly keyed by CAF quotient familial ranges (Context.md: Pricing, CAF). Validity-bound so past years' pricing is preserved.
| Column | Type | Notes |
| --- | --- | --- |
| `program_id` | uuid | FK, nullable (nullable = municipality-wide tier) |
| `label` | text | |
| `amount_cents` | int | EUR minor units; `CHECK >= 0` |
| `currency` | text | default `EUR` |
| `rule_type` | enum `pricing_rule_type` | `FLAT \| QUOTIENT` |
| `quotient_min` / `quotient_max` | int | nullable (QUOTIENT rule) |
| `valid_from` / `valid_to` | date | nullable range |
- **Indexes/constraints:** index `program_id`; `CHECK(quotient_max >= quotient_min)` when present.

## `caf_indicators`
**Why:** the CAF indicators a municipality reports on (Context.md: CAF settings/statistics). Configurable — no hardcoded CAF values. Actual declarations/aggregates are computed in the reporting phase (Phase 5) over operational data; a `caf_declarations` snapshot table is added then.
| Column | Type | Notes |
| --- | --- | --- |
| `key` | text | e.g. `heures_enfance` |
| `label` | text | |
- **Indexes/constraints:** `UNIQUE(municipality_id, key)`.

---

# Layer 3 — People

## `families` 🗑
**Why:** the household unit grouping children and guardians; holds address (for GIS/statistics) and CAF quotient (for pricing).
| Column | Type | Notes |
| --- | --- | --- |
| `reference` | text | nullable municipal reference; unique per municipality when present |
| `name` | text | household label |
| `address_street` / `address_postal_code` / `address_city` | text | |
| `neighborhood_id` | uuid | FK, nullable |
| `caf_number` | text | nullable |
| `caf_quotient` | int | nullable; drives pricing tier |
- **Relationships:** parent of `guardians`, `children`; owns `documents`.
- **Indexes/constraints:** partial `UNIQUE(municipality_id, reference) WHERE reference IS NOT NULL`; index `neighborhood_id`. CAF/PII.

## `guardians` 🗑
**Why:** the responsible adults (parents/legal guardians) linked to a family and, per relationship, to children. Data-only now; a parent-portal login is a future extension.
| Column | Type | Notes |
| --- | --- | --- |
| `family_id` | uuid | FK → families |
| `first_name` / `last_name` | text | |
| `email` / `phone` | text | nullable |
- **Relationships:** `guardians *—* children` via `guardianships`.
- **Indexes/constraints:** index `family_id`.

## `children` 🗑
**Why:** any **young beneficiary** served (childhood *and* youth). Central operational subject. See open decision D1 (unify child/youth vs split) in [design-review.md](design-review.md).
| Column | Type | Notes |
| --- | --- | --- |
| `family_id` | uuid | FK → families, nullable |
| `first_name` / `last_name` | text | |
| `birth_date` | date | drives age brackets |
| `sex` | enum `sex` | nullable |
| `school_structure_id` | uuid | FK → structures (their school), nullable |
| `neighborhood_id` | uuid | FK, nullable |
- **Relationships:** belongs to `families`; `*—*` guardians; parent of `enrollments`, `attendance_records`, `meals`, `trip_participations`, `passport_jeunes`, `pais` 🔒, `handicap_followups` 🔒, `documents`.
- **Indexes/constraints:** index `family_id`, `school_structure_id`, `birth_date`. PII (minor).

## `guardianships`
**Why:** the child↔guardian link carrying the **relationship type** and primary-contact flag. A child may have several guardians; a guardian several children.
| Column | Type | Notes |
| --- | --- | --- |
| `child_id` | uuid | FK → children |
| `guardian_id` | uuid | FK → guardians |
| `relationship` | enum `guardian_relationship` | `MOTHER \| FATHER \| LEGAL_GUARDIAN \| OTHER` |
| `is_primary` | boolean | primary contact |
- **Indexes/constraints:** `UNIQUE(child_id, guardian_id)`; index `guardian_id`.

## `enrollments` 🗑
**Why:** a child's registration to a program for a school year/period — the link between people and the offer, and the basis for sessions/attendance/billing.
| Column | Type | Notes |
| --- | --- | --- |
| `child_id` | uuid | FK → children |
| `program_id` | uuid | FK → programs |
| `school_year_id` | uuid | FK → school_years |
| `period` | text | nullable (periscolaire/vacances) |
| `status` | enum `enrollment_status` | `PENDING \| CONFIRMED \| CANCELLED` |
| `starts_on` / `ends_on` | date | nullable |
- **Indexes/constraints:** partial `UNIQUE(child_id, program_id, school_year_id, period) WHERE deleted_at IS NULL`; index `program_id`, `school_year_id`.

---

# Layer 4 — Operations (first-pass; Prisma refined per-domain in Phase 4)

## `sessions`
**Why:** a **dated occurrence** of a program at a structure that a child can attend — the anchor for attendance and meals.
| Column | Type | Notes |
| --- | --- | --- |
| `program_id` | uuid | FK → programs |
| `structure_id` | uuid | FK → structures |
| `date` | date | |
| `starts_at` / `ends_at` | time | |
| `capacity` | int | nullable |
- **Indexes/constraints:** index `(structure_id, date)`, `(program_id, date)`; `CHECK(ends_at > starts_at)`.

## `attendance_records` 🗑
**Why:** presence of a child at a session — the core daily operational act (tablet-first). One record per child per session.
| Column | Type | Notes |
| --- | --- | --- |
| `session_id` | uuid | FK → sessions |
| `child_id` | uuid | FK → children |
| `status` | enum `attendance_status` | `PRESENT \| ABSENT \| EXCUSED \| LATE` |
| `checked_in_at` / `checked_out_at` | timestamptz | nullable |
| `notes` | text | nullable |
- **Indexes/constraints:** `UNIQUE(session_id, child_id) WHERE deleted_at IS NULL`; index `child_id`, `(municipality_id, session_id)`.

## `meals`
**Why:** meal planning/consumption per session/child, including dietary constraints (Context.md: Meals). *Refined in Phase 4.*
| Column | Type | Notes |
| --- | --- | --- |
| `session_id` | uuid | FK, nullable |
| `child_id` | uuid | FK → children |
| `date` | date | |
| `type` | text | e.g. lunch/snack |
| `consumed` | boolean | |
| `dietary_flags` | jsonb | allergies/regime (links to PAI where relevant) |
- **Indexes/constraints:** index `(municipality_id, date)`, `child_id`.

## `trips` 🗑
**Why:** organized outings (Context.md: Trips). *Refined in Phase 4.*
| Column | Type | Notes |
| --- | --- | --- |
| `name` | text | |
| `date` | date | |
| `structure_id` | uuid | FK, nullable |
| `destination` | text | |
| `capacity` | int | nullable |
- **Indexes/constraints:** index `(municipality_id, date)`.

## `trip_participations`
**Why:** which children join a trip.
| Column | Type | Notes |
| --- | --- | --- |
| `trip_id` | uuid | FK → trips |
| `child_id` | uuid | FK → children |
| `status` | enum `participation_status` | `REGISTERED \| CANCELLED \| ATTENDED` |
- **Indexes/constraints:** `UNIQUE(trip_id, child_id)`.

## `passport_jeunes`
**Why:** the municipal youth benefit/program (Context.md: Passport Jeune) — configurable per municipality. *Refined in Phase 4.*
| Column | Type | Notes |
| --- | --- | --- |
| `child_id` | uuid | FK → children |
| `number` | text | |
| `issued_on` / `valid_until` | date | |
| `status` | text | |
- **Indexes/constraints:** `UNIQUE(municipality_id, number)`.

## `pais` 🔒 🗑
**Why:** *Projet d'Accueil Individualisé* — individualized (often medical) care plan. **Art. 9 sensitive.** Dedicated permissions + audited access.
| Column | Type | Notes |
| --- | --- | --- |
| `child_id` | uuid | FK → children |
| `type` | text | |
| `starts_on` / `ends_on` | date | |
| `details` | text/jsonb | restricted; column-encryption candidate |
- **Indexes/constraints:** index `child_id`. Access gated by `pai.*`; every read audited.

## `handicap_followups` 🔒 🗑
**Why:** disability accommodation tracking (Context.md: Handicap follow-up). **Art. 9 sensitive.**
| Column | Type | Notes |
| --- | --- | --- |
| `child_id` | uuid | FK → children |
| `details` | text/jsonb | restricted |
| `accommodations` | jsonb | |
- **Indexes/constraints:** index `child_id`. Same controls as `pais`.

## `documents` 🗑
**Why:** files attached to a child/family/etc., stored in Supabase Storage with access-controlled paths (Context.md: Documents). Uses a **polymorphic owner** — see open decision D2.
| Column | Type | Notes |
| --- | --- | --- |
| `owner_type` | text | `child \| family \| guardian \| structure` |
| `owner_id` | uuid | id within owner_type |
| `type` | text | document category |
| `storage_path` | text | Supabase Storage key |
| `file_name` / `mime_type` | text | |
| `size_bytes` | int | |
| `uploaded_by` | uuid | → users |
- **Indexes/constraints:** index `(municipality_id, owner_type, owner_id)`.

## `notifications`
**Why:** in-app notifications to users (Context.md: Notifications).
| Column | Type | Notes |
| --- | --- | --- |
| `recipient_user_id` | uuid | → users |
| `type` | text | |
| `payload` | jsonb | |
| `read_at` | timestamptz | nullable |
- **Indexes/constraints:** index `(recipient_user_id, read_at)`.

## `email_templates`
**Why:** per-tenant templated emails (Context.md: Emails), branded per municipality.
| Column | Type | Notes |
| --- | --- | --- |
| `key` | text | |
| `subject` / `body` | text | |
- **Indexes/constraints:** `UNIQUE(municipality_id, key)`.

## `email_logs`
**Why:** record of emails sent (deliverability, audit).
| Column | Type | Notes |
| --- | --- | --- |
| `template_key` | text | nullable |
| `to_address` | text | |
| `subject` | text | |
| `status` | enum `email_status` | `QUEUED \| SENT \| FAILED` |
| `sent_at` | timestamptz | nullable |
| `error` | text | nullable |
- **Indexes/constraints:** index `(municipality_id, status, created_at)`.

---

## Summary — table count by layer

| Layer | Tables |
| --- | --- |
| Foundation | communities, municipalities, users, memberships, roles, permissions, role_permissions, membership_structures, audit_logs, settings, municipality_modules, email_domains (12) |
| Configuration | neighborhoods, structures, school_years, holiday_periods, public_holidays, opening_hours, programs, pricing_tiers, caf_indicators (9) |
| People | families, guardians, children, guardianships, enrollments (5) |
| Operations | sessions, attendance_records, meals, trips, trip_participations, passport_jeunes, pais, handicap_followups, documents, notifications, email_templates, email_logs (12) |

**38 tables.** Enums: `municipality_status, user_status, membership_status, audit_severity, structure_type, holiday_zone, weekday, program_type, pricing_rule_type, sex, guardian_relationship, enrollment_status, attendance_status, participation_status, email_status`.
