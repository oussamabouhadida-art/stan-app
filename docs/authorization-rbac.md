# Authorization & RBAC

How Stan decides *what* an authenticated user may do. Identity is in [authentication.md](authentication.md); isolation is in [multi-tenancy.md](multi-tenancy.md).

Decision record: [ADR-0005](adr/ADR-0005-rbac-model.md).

---

## 1. Principles

1. **RBAC is data, not code.** Roles and their permissions are database rows, editable from Administration. No role name is hardcoded (Context.md: *No Hardcoded Data*).
2. **Per-municipality roles.** Each municipality owns its roles; two municipalities can have completely different role structures. A user's rights depend on *which* municipality they're acting in.
3. **Permissions are the atoms.** Code checks **permissions**, never role names. `can('attendance.write')`, never `if (role === 'Animateur')`. This lets municipalities rename/restructure roles freely without touching code.
4. **Deny by default.** No permission → not allowed. There is no implicit access.
5. **Authorization is a server concern.** The UI *reflects* permissions (hides buttons) for UX, but every Server Action / Route Handler / service **re-checks** them. Hidden UI is never a security control.

---

## 2. The model

```
Permission           (global catalog — the fixed vocabulary of capabilities)
    │
    │  RolePermission (which permissions a role grants)
    ▼
Role                 (per-municipality, editable; e.g. "Directeur", "Animateur")
    │
    │  Membership    (a user's role within a municipality)
    ▼
User ── Membership ──► Municipality
```

- **`Permission`** — global, code-defined catalog of capability keys (see §3). Municipalities don't invent permissions; they compose them into roles. This keeps the code's permission checks meaningful across all tenants.
- **`Role`** — tenant-scoped, named and configured per municipality, mapped to a set of permissions via `RolePermission`.
- **`Membership`** — links a `User` to a `Municipality` with exactly one `Role` (and a status). A user has one membership per municipality, many across municipalities.

> A user may have *different* roles in different municipalities. Authorization is always evaluated within the active `TenantContext`.

---

## 3. Permission catalog

Permissions follow a stable **`domain.action`** convention, grouped by business domain. The catalog is versioned in code (`@stan/core`) and seeded into the DB; new capabilities are added with the feature that needs them.

Examples (illustrative — the full list is produced alongside each feature):

| Key | Grants |
| --- | --- |
| `family.read` / `family.write` | View / edit families |
| `child.read` / `child.write` | View / edit children |
| `attendance.read` / `attendance.write` | View / record attendance |
| `meal.read` / `meal.write` | View / manage meals |
| `activity.manage` | Create/configure activities & sessions |
| `document.read` / `document.write` | View / manage documents |
| `pai.read` / `pai.write` | View / manage PAI (sensitive — see §6) |
| `report.view` | Access dashboards & statistics |
| `admin.config` | Edit municipality configuration |
| `admin.access` | Manage roles, permissions, users |
| `admin.tools` | Maintenance tools (import/export, etc.) |
| `municipality.provision` | Platform-level: install/manage municipalities (super-admin) |

Conventions:
- `read` < `write` < `manage` express increasing capability but are **independent flags**, not a hierarchy the code assumes — a role may have `write` without `manage`.
- Sensitive domains (PAI, handicap follow-up, health) always have their own permissions and are never bundled into a generic `read`.

---

## 4. How a check works

```ts
// In a service — the authoritative check.
function assertCan(ctx: TenantContext, permission: PermissionKey): void {
  if (ctx.isSuperAdmin && isPlatformPermission(permission)) return;
  if (!ctx.permissions.has(permission)) {
    throw new ForbiddenError(permission);
  }
}
```

- Permissions are resolved **once** per request into `ctx.permissions` (a `Set`) and passed explicitly.
- Every service method that performs a protected operation calls `assertCan(ctx, '…')` **first**, before any work.
- The **tenant scoping is orthogonal**: even with `child.read`, the tenant-scoped client only ever returns *this* municipality's children. Permission answers "may you do this action?"; tenancy answers "on whose data?". Both must pass.

---

## 5. UI reflection

- The frontend receives the resolved permission set and uses it to **show/hide/disable** actions (`<Can permission="attendance.write">…</Can>`), keeping the interface honest and uncluttered.
- This is a **UX affordance only**. The server never trusts it. A crafted request without the permission is rejected by the service.

---

## 6. Sensitive data & least privilege

- **PAI, handicap follow-up, and health information** are gated by dedicated permissions and additionally flagged in audit (every access logged). Roles granting them are expected to be narrow.
- Administration enforces **least privilege** by defaulting new roles to no permissions; the admin opts in.
- A future enhancement (roadmap) adds **structure-scoped** authorization (an animator limited to their own leisure centre) as an additional constraint layer on top of permissions — designed for but not required at MVP.

---

## 7. Defaults on municipality install

- The municipality config file (see [municipality-initialization.md](municipality-initialization.md)) may declare an initial set of roles with their permissions — but these are **seed data**, fully editable afterwards, not code.
- The platform ships a **recommended role template** (e.g. Directeur / Coordinateur / Animateur / Agent d'accueil / Lecture seule) as an *optional* starting point in config. It is a convenience, never a hardcoded assumption.

---

## 8. Rules for engineers (enforced)

1. Never branch on a role name. Check a **permission key**.
2. Add new permission keys to the catalog in `@stan/core` and seed them; reference them by the exported constant, never a string literal scattered in code.
3. Every protected service method calls `assertCan` before doing work — and this is covered by a test.
4. Sensitive-data access is both permission-gated and audited.
5. UI `Can`-gating is required for good UX but is never the only check.
