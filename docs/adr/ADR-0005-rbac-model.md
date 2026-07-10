# ADR-0005 — Permission-based RBAC with per-municipality roles

**Status:** Accepted (Phase 0)

## Context

Municipalities have different organizational structures and must configure access **without developer involvement** — no hardcoded roles (Context.md). A user may hold **different roles in different municipalities**. We need authorization that is data-driven, safe by default, and stable against role renaming/restructuring per tenant.

## Decision

Adopt **permission-based RBAC**:

- A **global `Permission` catalog** defines atomic capabilities as stable `domain.action` keys (code-defined, seeded).
- **`Role`s are per-municipality**, editable in Administration, composed of permissions via `RolePermission`.
- **`Membership`** links a `User` to a `Municipality` with one role; a user has many memberships across municipalities.
- **Code checks permissions, never role names** (`assertCan(ctx, 'attendance.write')`). Authorization is **deny-by-default** and always evaluated within the active `TenantContext`.
- The UI reflects permissions (show/hide) for UX, but **every service re-checks** them; hidden UI is never a security control.
- Tenant scoping (ADR-0002) is orthogonal: permission answers "may you do this action?", tenancy answers "on whose data?". Both must pass.

An optional recommended role template ships as **config/data**, never as code.

## Consequences

- **Positive:** municipalities restructure/rename roles freely without code changes; the permission vocabulary stays meaningful across all tenants; least-privilege by default; sensitive domains (PAI/health) get dedicated permissions.
- **Positive:** testable — permission-denial tests are required for every protected operation.
- **Negative / cost:** more moving parts than hardcoded roles; the permission catalog must be curated as features grow — accepted, and enforced via a central catalog with typed constants.
- **Negative:** fine-grained, per-record/structure scoping isn't covered by role+permission alone — deferred to a future structure-scoped authorization layer, designed for but not required at MVP.

## Alternatives considered

- **Role-name checks in code (`if role === 'Animateur'`):** simplest, but bakes one municipality's org model into code and breaks the no-hardcoding rule. Rejected outright.
- **Full ABAC/policy engine (e.g. OPA):** maximally flexible, but heavy and premature; permission-based RBAC covers our needs with far less complexity. Revisit only if policy needs outgrow RBAC.

See [authorization-rbac.md](../authorization-rbac.md).
