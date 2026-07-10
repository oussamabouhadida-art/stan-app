# Database design (Phase 1)

This folder is the **Phase 1 deliverable**: the data model for Stan, designed for validation **before any application code**. Nothing here is migrated or live — `schema.prisma` is a *proposal*. Once you validate it, it moves to `packages/db` and becomes the first real migration in Phase 2.

Read in this order:

| Document | Purpose |
| --- | --- |
| [erd.md](erd.md) | Entity-Relationship diagrams — the whole model at a glance, then per-domain |
| [entities.md](entities.md) | The entity dictionary — **every table explained**: why it exists, its columns, relationships, indexes, constraints |
| [schema.prisma](schema.prisma) | The Prisma schema **proposal** (annotated) |
| [design-review.md](design-review.md) | Conventions applied, **simplifications found, self-critique, and the open decisions I need you to confirm** |

## Scope & depth

The model spans four layers, designed at decreasing depth on purpose (foundations must be right *now*; far-future operational domains are designed coherently but finalized when built — see [roadmap.md](../roadmap.md)):

1. **Foundation** — tenancy, identity, access/RBAC, audit, config-meta. *Full production detail.* Phases 2–3 build these first.
2. **Configuration / structural** — structures, calendars, opening hours, programs, pricing, CAF, neighborhoods. *Full detail.*
3. **People** — families, guardians, children/youth, guardianships, enrolments. *Full detail.*
4. **Operations** — sessions, attendance, meals, trips, Passport Jeune, PAI, handicap, documents, notifications, emails. *Designed at entity level; Prisma refined per-domain in Phase 4.* Marked accordingly in the schema.

## Rules this model obeys

Every table follows [database-philosophy.md](../database-philosophy.md): UUID PKs, base columns (`created_at`/`updated_at`, `municipality_id` when tenant-scoped, `created_by`/`updated_by`, `deleted_at`/`deleted_by` when soft-deletable), snake_case plural tables, and RLS on every tenant table (added in migration, not visible in the Prisma model). Isolation is enforced by the tenant-scoped Prisma extension + RLS ([multi-tenancy.md](../multi-tenancy.md)).

## Your gate

Phase 1 stops for your validation. The **open decisions** in [design-review.md](design-review.md) (§4) are the ones I most want your call on before this becomes a migration.
