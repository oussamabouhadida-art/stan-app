# Audit

Stan keeps an **append-only audit trail** of who did what, in which municipality, and when. Audit serves operations (troubleshooting), security (breach investigation), and compliance (GDPR accountability).

Related: [security.md](security.md), [database-philosophy.md](database-philosophy.md).

---

## 1. Principles

1. **Append-only.** Audit records are never updated or deleted by the application. They are written, never mutated.
2. **Tenant-scoped.** Every audit entry carries `municipality_id`; a municipality sees only its own trail (super-admin/platform events are separated).
3. **Actor-attributed.** Every entry records the acting `user_id` (or `system`) and the membership/role in effect.
4. **Written by the application layer, not guessed at the DB.** Services emit audit events as an explicit, meaningful part of the operation — capturing *intent*, not just a raw row diff.
5. **Non-blocking correctness, but reliable.** Audit writes participate in the same transaction as the change for critical events so a committed change always has its audit entry; best-effort async is used only for read/access logging where volume is high.

---

## 2. What we audit

**Always:**
- Authentication events: login, logout, failed login, password reset, MFA changes, municipality switch.
- Authorization/config changes: role created/edited, permission grant/revoke, user invited/suspended, membership changes.
- Municipality configuration changes: any edit to identity, structures, schedules, calendars, pricing, CAF settings, modules, email domains, theming.
- Municipality provisioning: install, update, super-admin "support access" grants/uses.
- Sensitive-data access: reads and writes of PAI, handicap follow-up, health information.
- Data lifecycle: soft delete, restore, hard delete, GDPR export, GDPR erasure, bulk import/export.

**Selectively (configurable):**
- Reads of ordinary business data (can be enabled for high-assurance municipalities; off by default to control volume).

---

## 3. Audit record shape

The concrete Prisma model is finalized in Phase 1; the shape:

| Field | Meaning |
| --- | --- |
| `id` | uuid |
| `municipality_id` | tenant (nullable for platform-level events) |
| `actor_user_id` | who (nullable for `system`) |
| `actor_membership_id` | role/membership in effect |
| `action` | stable key, e.g. `attendance.record`, `role.permission.grant`, `config.pricing.update` |
| `entity_type` / `entity_id` | the affected record |
| `summary` | human-readable description (localized-safe, no raw PII where avoidable) |
| `metadata` | structured JSON: before/after for config changes (PII-minimized), request id, ip, user agent |
| `severity` | info / notice / security |
| `created_at` | when (immutable) |

- **Before/after diffs** are captured for configuration and permission changes so admins can see exactly what changed.
- **PII minimization:** audit metadata avoids storing raw sensitive values; it records *that* a sensitive field changed and by whom, not necessarily the value, per [security.md](security.md).

---

## 4. How services emit audit events

- An infrastructure `auditWriter` is provided to services (dependency, not a global import).
- Services call it with a **typed action key** and structured context. Action keys come from a central catalog (like permission keys) — no free-form strings scattered in code.
- For critical events, the audit write is enlisted in the **same DB transaction** as the business change: either both commit or both roll back. This guarantees the trail is complete and consistent.

```ts
await tx.run(async (repo) => {
  await repo.attendance.record(ctx, input);
  await auditWriter.log(ctx, {
    action: AuditAction.AttendanceRecord,
    entity: { type: 'attendance', id },
    summary: `Recorded attendance for session ${sessionId}`,
    metadata: { sessionId, childId },
  });
});
```

---

## 5. Access & retention

- **Access:** viewing the audit trail is permission-gated (`admin.access` or a dedicated `audit.read`). Municipality admins see their tenant's trail; platform operators see platform events.
- **Immutability:** enforced by convention (no update/delete methods exist) and by database privileges (the application role has `INSERT`/`SELECT` but not `UPDATE`/`DELETE` on the audit table).
- **Retention:** audit records have their own retention window (typically longer than business data for accountability), configured per compliance needs. Purging expired audit records is itself an audited, restricted operation.
- **RLS** applies to the audit table like any tenant table.

---

## 6. Relationship to soft delete & history

- **Soft delete** (`deleted_at`) answers "is this record currently live?" and enables restore.
- **Audit** answers "what happened to it, by whom, when?".
- Together they preserve the history Context.md requires. Neither replaces the other: soft delete is state; audit is narrative.

---

## 7. Rules for engineers (enforced)

1. Every mutating service operation on auditable data emits an audit event with a typed action key.
2. Critical audit writes share the transaction with the change they describe.
3. Never expose an `update`/`delete` path on audit records.
4. Never log raw sensitive values; record the fact of access/change and the actor.
5. Sensitive-data reads (PAI, handicap, health) are audited even though they are reads.
