# Roadmap

The phased plan to build Stan from documentation to a commercial multi-tenant SaaS. We build **incrementally, one bounded domain at a time**, keeping the app runnable and every quality gate green (Context.md, *Development Rules*).

Sequencing principle: **foundations before features**. Tenancy, auth, RBAC, audit, and Administration come first because every later feature depends on them. We never build a business feature on an unbuilt foundation.

---

## Phase 0 — Design & Documentation ← *current*

Analysis, architecture, and documentation only. **No business code.**

**Deliverables:** this `/docs` set, `README.md`, ADRs, and the config file schema. **Exit criteria:** documentation reviewed and validated by the founder.

---

## Phase 1 — Database design

Design the data model for validation **before any code**.

**Deliverables:** complete ERD; entity dictionary (every table explained — why it exists, columns, relationships); relationships, indexes, constraints; naming applied; **Prisma schema proposal**; a self-critique challenging the design and listing simplifications.
**Exit criteria:** schema validated by the founder. No application code until then.

---

## Phase 2 — Project initialization & foundations

Stand up the monorepo and the cross-cutting machinery every feature relies on.

- Turborepo + pnpm workspaces; `apps/web` + `packages/*` per [folder-structure.md](folder-structure.md).
- Tooling: strict TS, ESLint (+ boundary/security rules), Prettier, Husky, lint-staged, commitlint.
- Prisma + Supabase wired (EU); first migration; **tenant-scoped client extension**; **RLS** on tenant tables; isolation tests.
- Supabase Auth + session middleware + `TenantContext` resolution.
- shadcn/ui base in `@stan/ui`; app shell; theming from tenant config.
- Config loader `@stan/config` + validation `@stan/validation`.
- GitHub Actions CI/CD; Vercel preview + production; `.env.example`.

**Exit criteria:** app deploys to Vercel; login works; a seeded demo tenant is isolated; all gates green.

---

## Phase 3 — Tenancy, identity & Administration core

The **heart of the application** (Context.md, *Administration*).

- Municipality, User, Membership, Role, Permission, RolePermission — models + services + UI.
- **Administration** module: municipality identity/theming, structures, roles & permissions, users (invite/suspend), modules toggle, settings — replacing legacy `/config`, `/acces`, `/outils_maintenance`.
- **Audit** infrastructure + viewer.
- **Municipality provisioning** from one YAML/JSON file (dry-run, atomic, idempotent) — [municipality-initialization.md](municipality-initialization.md).
- Shared **import/export** framework skeleton.

**Exit criteria:** a super-admin can install a municipality from a file; an admin can configure it entirely through the UI with no code changes; every action audited.

---

## Phase 4 — Core operational domains

The daily-work features, each end-to-end (DB → service → UI → tests → deploy):

1. **Structures & calendars** — school year, zones A/B/C, holiday periods, public holidays, opening hours.
2. **Families & Children** — records, relationships, documents, PAI, handicap follow-up (sensitive-data controls).
3. **Youth** — youth records; Passport Jeune.
4. **Activities & Sessions** — programs/workshops; after-school and holiday sessions; enrolment; capacity/age rules.
5. **Attendance** — tablet-first recording per session; anomalies.
6. **Meals** — planning and tracking.
7. **Trips** — organization and participation.

Each domain ships with pricing hooks where relevant, full validation, permissions, audit, and import/export.

**Exit criteria:** a municipality runs real daily operations on Stan.

---

## Phase 5 — Reporting, CAF & GIS

- **Reporting/dashboards** (Recharts): operational + strategic indicators.
- **CAF statistics**: configurable indicators and exports.
- **GIS** (Leaflet): structures, neighborhoods, catchment, maps.
- Cross-municipality (community) reporting via the authorized reporting service.

**Exit criteria:** municipalities replace their manual reporting and Excel with reliable, exportable data.

---

## Phase 6 — Communication & documents

- **Documents** management (Storage, access-controlled).
- **Notifications** (in-app) and **Emails** (templated, per-tenant domains/branding).

---

## Phase 7 — Hardening & commercialization

- Performance passes, accessibility audit, security review, load testing at multi-tenant scale.
- MFA/SSO where customers require it; advanced structure-scoped authorization.
- Onboarding tooling, tenant lifecycle (billing/subscription if in scope), operational runbooks.

---

## Phase 8 — AI features (future)

Built on the clean data foundation, EU-hosted models, personal data respected (Context.md, *Future AI Features*): automatic report generation, attendance anomaly detection, CAF assistance, planning assistant, automatic email drafting, predictive dashboards, natural-language search, document summarization.

---

## Cross-cutting, every phase

- Documentation and ADRs kept current with decisions.
- Isolation, auth, validation, audit, and accessibility are part of **every** feature's Definition of Done — never deferred.
- Ship incrementally; keep the app runnable; commit meaningfully; deploy and verify.

> Timeboxing is intentionally omitted here; phases are ordered by dependency, not dated. Dates are set with the founder as capacity is known.
