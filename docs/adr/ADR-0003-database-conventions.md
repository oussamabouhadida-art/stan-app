# ADR-0003 — Database conventions: UUID keys, base columns, soft delete

**Status:** Accepted (Phase 0)

## Context

A shared multi-tenant schema needs consistent, safe conventions from the first table: identifier type, mandatory columns, delete semantics, and history. Municipal records have legal/operational retention needs and must be auditable. Sequential integer keys would leak tenant record counts and enable enumeration.

## Decision

- **Primary keys are `uuid`** (`gen_random_uuid()`): non-enumerable, URL-safe, client-generatable, compatible with Supabase Auth. Migrate to **UUID v7** later if insertion locality becomes a measured problem — never to sequential integers.
- **Base columns on every business table:** `id`, `created_at`, `updated_at`; `municipality_id` when tenant-scoped; `created_by`/`updated_by` when user-authored; `deleted_at`/`deleted_by` when soft-deletable.
- **Soft delete** for business/operational data (`deleted_at`), auto-excluded from default reads by the central Prisma extension. **Hard delete** reserved for GDPR erasure, retention purges, and truly transient rows.
- **DB enforces integrity:** foreign keys with explicit `ON DELETE`, `NOT NULL` by default, `CHECK` for invariants, `UNIQUE` (often composite with `municipality_id`, partial on `deleted_at IS NULL`), and RLS.
- **Naming:** snake_case plural tables, snake_case columns, `PascalCase` Prisma models mapped via `@@map`.
- **Temporal config:** calendars/hours/pricing are validity-bound (school year or `valid_from`/`valid_to`) so history is preserved.
- **Money** as integer minor units / `numeric`, never float; **timestamps** as `timestamptz`.

## Consequences

- **Positive:** consistent, safe, auditable tables; no enumeration/count leakage; recoverable deletes; historically-accurate reporting.
- **Positive:** the central extension makes tenant scoping + soft-delete filtering automatic, so individual queries can't forget them.
- **Negative / cost:** UUIDs are larger than ints and less cache-friendly for insertion order — mitigated by good indexing and the UUID v7 escape hatch; soft delete complicates uniqueness (handled via partial unique indexes) and requires purge jobs for retention.

## Alternatives considered

- **Auto-increment integer PKs:** compact and fast, but leak counts and enable enumeration across a shared multi-tenant DB. Rejected.
- **Hard delete everywhere:** simpler, but loses history and makes accidental deletion unrecoverable — unacceptable for municipal records. Rejected.
- **`created_at`/`updated_at` only, no `created_by`/`deleted_by`:** insufficient for audit/accountability. Rejected for business data.

See [database-philosophy.md](../database-philosophy.md).
