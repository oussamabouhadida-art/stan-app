# Security & GDPR

Stan holds sensitive personal data about **minors and families** for public institutions. Security is a first-class, non-negotiable requirement. This document defines the threat model, controls, and GDPR posture.

Related: [multi-tenancy.md](multi-tenancy.md), [authentication.md](authentication.md), [authorization-rbac.md](authorization-rbac.md), [audit.md](audit.md).

---

## 1. Threat model (what we defend against)

| Threat | Primary control |
| --- | --- |
| Cross-tenant data access | Two-wall isolation: tenant-scoped Prisma + Postgres RLS ([multi-tenancy.md](multi-tenancy.md)) |
| Broken access control (IDOR, missing checks) | Deny-by-default RBAC; every service re-checks permissions; opaque UUID keys |
| Credential compromise | Supabase Auth, http-only cookies, rate limiting, MFA (roadmap), no self-rolled crypto |
| Injection (SQL/XSS) | Prisma parameterized queries; Zod validation; React auto-escaping; no `dangerouslySetInnerHTML` on untrusted data |
| CSRF | Server Actions' origin protection + `SameSite` cookies; state-changing Route Handlers require CSRF/double-submit or signature |
| Secret leakage | Encrypted env management, no secrets in code/logs, least-privilege keys |
| Data exfiltration via exports | Exports are permission-gated, tenant-scoped, and audited |
| Abuse / brute force / scraping | Rate limiting on auth and sensitive endpoints |
| Supply-chain | Locked deps, Dependabot/audit in CI, minimal footprint |

---

## 2. Data residency (GDPR — mandatory)

- Personal data of French residents is stored and processed **in the EU**: Supabase project in an **EU region**, Vercel **EU function regions**, EU-hosted email/provider services.
- We maintain a **Data Processing Agreement (DPA)** posture: Stan is a **data processor**; each municipality is the **data controller**. Contracts and sub-processor lists are documented.
- No personal data is sent to non-EU services without an assessed legal basis. AI features (roadmap) must use EU-region model hosting or be explicitly scoped to non-personal data.

---

## 3. Personal data classification

Phase 1 tags every field. Categories:

| Class | Examples | Handling |
| --- | --- | --- |
| Identifying PII | names, DOB, address, contact | Access-controlled, exportable, erasable |
| Sensitive (Art. 9) | PAI/health, handicap follow-up, dietary/medical | Dedicated permissions, every access audited, candidate for column-level encryption, strict retention |
| Operational | attendance, meals, activities | Tenant-scoped, retained per policy |
| Config | structures, schedules, pricing | Not personal, but tenant-scoped |

Data concerning **minors** is treated with heightened care throughout.

---

## 4. GDPR rights implementation

| Right | Implementation |
| --- | --- |
| Access / portability | Per-subject **export** service assembles all data for a person (family/child/agent) into a portable file; permission-gated + audited |
| Rectification | Standard edit flows with audit history |
| Erasure ("right to be forgotten") | Dedicated **erasure service**: hard-deletes or irreversibly anonymizes the subject's PII while preserving lawfully-required aggregates; fully audited. Distinct from routine soft delete |
| Restriction / objection | Status flags that block processing without deleting |
| Retention | Per-category retention windows; a scheduled job purges expired soft-deleted rows |

Erasure and retention are **explicit, audited services** — never ad-hoc SQL. See [audit.md](audit.md) and [database-philosophy.md](database-philosophy.md).

---

## 5. Secrets management

- Secrets (Supabase keys, DB URL, service tokens) live in **Vercel encrypted environment variables** and local `.env` files that are **git-ignored**. A committed `.env.example` documents required keys with no values.
- **Least privilege keys:** the browser only ever receives the Supabase *anon* key (RLS-protected). The service-role key is server-only and never exposed to the client bundle. The Prisma connection string is server-only.
- No secret is ever logged. Structured logging redacts known-sensitive fields.
- Key rotation procedure documented in [deployment.md](deployment.md).

---

## 6. Application-layer controls

- **Validation everywhere:** every external input (form, action, route, import file, query param) is parsed with **Zod** at the boundary. Unvalidated input never reaches a service. See [coding-conventions.md](coding-conventions.md).
- **Output encoding:** React escapes by default; we forbid rendering untrusted HTML.
- **CSRF:** Next.js Server Actions include origin checks; cookies are `SameSite=Lax`, `Secure`, http-only. Non-action state-changing endpoints require an anti-CSRF measure or a verified signature.
- **Security headers:** strict `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, frame-ancestors denial — configured centrally and tested.
- **Rate limiting:** auth endpoints, export/import, and other sensitive or expensive operations are rate-limited per IP and per user/tenant (durable store, e.g. Supabase/Upstash). Limits are configurable.
- **File uploads:** validated type/size, scanned where feasible, stored in Supabase Storage with tenant-scoped access policies; never served from a path that bypasses authorization.

---

## 7. Auditability

Every security-relevant event (auth, permission changes, config changes, sensitive-data access, exports, erasure, super-admin access) is written to an **append-only audit log**. See [audit.md](audit.md). Audit is a security control, not just a feature: it enables breach investigation and demonstrates GDPR accountability.

---

## 8. Secure development lifecycle

- **CI gates:** typecheck, lint (incl. security lint rules), tests, and **isolation tests** must pass before merge. Dependency audit runs in CI. See [ci-cd.md](ci-cd.md).
- **Reviews:** any change touching auth, RBAC, tenancy, or PII handling requires explicit reviewer attention to this document.
- **No secrets/PII in test fixtures, logs, or error messages** returned to clients. Errors are typed and generic at the boundary; details go to server logs.
- **Least code:** the smaller the attack surface, the better — we avoid unnecessary dependencies and endpoints.

---

## 9. Incident readiness

- Structured logs + audit trail enable reconstruction of "who did what, in which tenant, when".
- A documented procedure covers: revoke keys, rotate secrets, identify affected tenants (isolation makes blast-radius analysis tractable), notify controllers within GDPR timelines.
- Backups (Supabase point-in-time recovery) and a tested restore path — see [deployment.md](deployment.md).

---

## 10. Security checklist (per feature)

Before a feature ships, confirm:

- [ ] Every input validated with Zod at the boundary.
- [ ] Every protected operation checks a permission and is tenant-scoped.
- [ ] New tables have `municipality_id`, RLS, and appropriate soft-delete.
- [ ] Sensitive-data access is permission-gated **and** audited.
- [ ] No secrets, PII, or stack traces leak to the client or logs.
- [ ] Exports/imports are permission-gated, tenant-scoped, audited, rate-limited.
- [ ] Personal fields are classified and covered by export/erasure.
