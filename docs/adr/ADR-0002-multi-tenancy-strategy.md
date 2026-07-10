# ADR-0002 — Multi-tenancy: shared schema + row scoping + RLS

**Status:** Accepted (Phase 0)

## Context

Stan must serve hundreds of municipalities from one codebase, with **mandatory data isolation** — no municipality can ever access another's data (Context.md). The isolation strategy determines operational cost, onboarding speed, and breach risk. It is the single most consequential technical decision in the system. Users may belong to **multiple** municipalities (confirmed), so isolation is per-request, not per-user-account.

## Decision

Use a **single database with a shared schema**. Every tenant-scoped table carries a `municipality_id`. Enforce isolation with **two independent walls**:

1. **Application layer (primary):** a Prisma Client **extension** that automatically injects `municipality_id` into every tenant-scoped query and `create`, and **throws** on any unscoped or mis-scoped tenant access. Repositories only ever use this scoped client. Unscoped tenant access is structurally impossible.
2. **Database layer (backstop):** **Row-Level Security** enabled and *forced* on every tenant table, keyed on a per-transaction `app.current_municipality` setting. Even an app-layer bug or raw SQL cannot cross tenants.

Tenant identity comes only from a server-resolved `TenantContext` (never from client input). A model registry + CI checks + mandatory isolation tests keep new tables safe.

## Consequences

- **Positive:** cheapest to operate (one DB, one migration path, one backup); onboarding a tenant is inserting rows, not provisioning infrastructure; two independent walls give defense-in-depth — a single mistake cannot breach isolation.
- **Positive:** efficient resource sharing; straightforward cross-tenant (community) reporting through an authorized aggregation path.
- **Negative / cost:** isolation becomes a discipline concern — mitigated by making unscoped access impossible (Wall 1) and adding RLS (Wall 2), plus blocking isolation tests.
- **Negative:** RLS + Prisma requires care (privileged connection, per-transaction setting) — documented and centralized in `@stan/core`/`@stan/db`.
- **Negative:** a single very large tenant shares the DB with small ones; monitored via indexing and query review; can be revisited if a tenant outgrows the shared model.

## Alternatives considered

- **Database per tenant:** strongest physical isolation, but hundreds of DBs to migrate/back up/monitor; high fixed cost per small municipality; slow onboarding. Rejected.
- **Schema per tenant:** migrations fan out across N schemas; tooling/connection complexity; marginal benefit over shared schema for our tenant sizes. Rejected.
- **Shared schema, app-layer only (no RLS):** one wall; a single forgotten filter is a breach. Rejected — we require defense-in-depth.

See [multi-tenancy.md](../multi-tenancy.md) for the full mechanism.
