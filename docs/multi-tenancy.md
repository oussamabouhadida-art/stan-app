# Multi-tenancy

> This is the most important technical document in the repository. A defect here is a data breach across municipalities. Read it before writing any code that touches the database.

Stan is multi-tenant: **one codebase and one database serve many municipalities**, and no municipality can ever access another's data. This document specifies the isolation model and how it is enforced in depth.

Decision record: [ADR-0002](adr/ADR-0002-multi-tenancy-strategy.md).

---

## 1. The tenant

- The **tenant is the `Municipality`**. Every piece of business data belongs to exactly one municipality.
- A **community of municipalities** (communauté de communes / agglomération) is modelled separately and _groups_ municipalities for reporting; it is not itself the isolation boundary. Isolation is always at the municipality level.
- A small amount of data is **global** (not tenant-scoped): the `User` identity record, platform-level `Permission` catalog definitions, and platform super-admin records. Everything else is tenant-scoped.

---

## 2. Isolation strategy: shared database, shared schema, row-level scoping

We use a **single database with a shared schema**, where every tenant-scoped table carries a `municipality_id` column. We rejected the alternatives:

| Strategy                              | Verdict | Why                                                                                                                                                                             |
| ------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Database per tenant                   | ✗       | Hundreds of DBs to migrate, back up, monitor. Unmanageable at our scale; huge fixed cost per small municipality.                                                                |
| Schema per tenant                     | ✗       | Migrations must fan out across N schemas; connection/tooling complexity; still one DB. Cost outweighs benefit for 2k–100k-inhabitant tenants.                                   |
| **Shared schema + `municipality_id`** | ✓       | One migration path, one backup, trivial to onboard a tenant, efficient. Isolation enforced by two independent mechanisms (below). Industry standard for B2B SaaS at this scale. |

The trade-off of a shared schema is that isolation becomes a **discipline problem** ("did every query filter by tenant?"). We remove the discipline problem by making unscoped access **structurally impossible** and adding a **database-level** backstop.

---

## 3. Defense in depth — two independent walls

Isolation does not rely on developers remembering to add `where municipalityId`. It is enforced by two mechanisms that fail independently:

### Wall 1 — Application layer: tenant-scoped Prisma client (Primary)

- Every request resolves a **`TenantContext`** early (see [authentication.md](authentication.md)): `{ userId, municipalityId, membershipId, permissions }`.
- Data access uses a **Prisma Client extension** (`@stan/db`, driven by the tenant-model registry in `@stan/core`) built from that context. The extension:
  - **automatically injects** `municipalityId` into the `where` of every `find*`, `update*`, `delete*`, `count`, `aggregate`, `groupBy` on any model tagged as tenant-scoped;
  - **automatically sets** `municipalityId` on every `create`/`createMany`;
  - **throws** if code somehow tries to override `municipalityId` with a different value, or runs a tenant-scoped query without a `TenantContext`.
- Repositories **only ever** receive this scoped client. There is no path in application code to a "raw" tenant query. A developer literally cannot write `child.findMany()` and get another tenant's children — the extension narrows it.

Models are classified in one registry (`@stan/core` `TENANT_SCOPED_MODELS`). Adding a new model forces an explicit decision: tenant-scoped or global. CI fails if a model with a `municipalityId` field is missing from the registry, and vice-versa.

### Wall 2 — Database layer: Postgres Row-Level Security (Backstop)

- **RLS is enabled and forced** on every tenant-scoped table.
- A policy restricts every row to `municipality_id = current_setting('app.current_municipality')`. The application sets that setting at the start of each transaction from the `TenantContext`.
- This means that **even a bug in Wall 1**, a raw SQL query, or a compromised code path cannot read or write across tenants — the database itself refuses.
- The Prisma migration for each tenant table includes its `ENABLE ROW LEVEL SECURITY` + policy. A CI check asserts no tenant table ships without RLS.

Two walls, different technologies, different failure modes. A single mistake cannot breach isolation.

> Supabase note: because Prisma connects with a privileged role, we do **not** rely on Supabase's default `auth.uid()`-based RLS for the Prisma path. Instead we set `app.current_municipality` per transaction and write policies against it. Any direct Supabase-client access (e.g. Storage, or future client-side reads) additionally uses Supabase-native RLS keyed on the user's memberships. Both are documented in [security.md](security.md).

---

## 4. `TenantContext`

```ts
type TenantContext = {
  userId: string; // global User.id (== Supabase auth user id)
  municipalityId: string; // the active tenant for this request
  membershipId: string; // the User↔Municipality membership in use
  roleId: string;
  permissions: ReadonlySet<string>; // resolved permission keys for this membership
  isSuperAdmin: boolean; // platform operator, bypasses tenant scoping only for platform ops
};
```

- Resolved once per request in middleware/layout and passed **explicitly** into services. It is never read from a global/singleton — explicit context is testable and safe under concurrency.
- The **active municipality** is chosen by the user when they have multiple memberships (see §5) and stored in a signed, http-only cookie plus validated on every request against the DB (a stale cookie can never grant access to a municipality the user was removed from).

---

## 5. Users across multiple municipalities

Confirmed product decision: **a person can belong to several municipalities** (e.g. shared staff in a communauté de communes).

```
User (global identity, 1:1 with Supabase auth user)
  └─< Membership (userId, municipalityId, roleId, status)
           └─ Role (tenant-scoped, editable in Administration)
                   └─< RolePermission ─ Permission (global catalog)
```

- A `User` has **many** `Membership` rows, at most one active per municipality.
- Roles and their permissions are **per municipality** and fully editable from Administration — no hardcoded roles. See [authorization-rbac.md](authorization-rbac.md).
- Switching municipality re-resolves the entire `TenantContext`; nothing from the previous tenant leaks (caches are keyed by `municipalityId`).
- Removing a membership immediately revokes access on the next request, regardless of cookie state.

---

## 6. Rules for engineers (enforced)

1. Every new business table **must** declare `municipalityId` and be registered as tenant-scoped, **or** be explicitly justified as global in code review.
2. Never construct a Prisma client by hand in a repository. Always receive the scoped client from the request's `TenantContext`.
3. Never accept `municipalityId` as user input for scoping — it comes only from the server-resolved `TenantContext`. (User input that _names_ a municipality, e.g. during super-admin provisioning, is a different, explicitly-authorized path.)
4. Every tenant table migration enables and forces RLS with the standard policy.
5. Cross-tenant reporting (community-level dashboards) goes through a dedicated, explicitly-authorized **reporting service** that aggregates per-municipality data the actor is entitled to — never by loosening the isolation walls.

---

## 7. Testing isolation

Isolation is covered by mandatory tests that ship with the tenancy infrastructure and run in CI:

- **Extension unit tests**: unscoped query throws; scoped query injects the right `municipalityId`; attempt to set a foreign `municipalityId` throws.
- **RLS integration tests** (against a real Postgres): with `app.current_municipality = A`, selecting tenant-B rows returns zero; inserting a tenant-B row is rejected.
- **Cross-tenant probe test**: seed two municipalities, authenticate as A, attempt (via service and via raw query) to read B's children/families/attendance — all must fail.

An isolation test failure blocks all merges. See [testing.md](testing.md).

---

## 8. Summary

| Layer       | Mechanism                                                  | Protects against                                  |
| ----------- | ---------------------------------------------------------- | ------------------------------------------------- |
| Application | Tenant-scoped Prisma extension                             | Forgotten `where`, accidental cross-tenant writes |
| Database    | Forced Row-Level Security                                  | App bugs, raw SQL, compromised code paths         |
| Identity    | Server-resolved `TenantContext`, re-validated each request | Stale cookies, revoked memberships                |
| Process     | Model registry + CI checks + isolation tests               | New tables shipped without isolation              |

Isolation is not a feature; it is a property enforced by construction.
