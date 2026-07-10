# Stan

> The reference SaaS platform for French municipalities to manage Childhood, Youth, After-school and Holiday programs.

**Stan** is a multi-tenant SaaS product. One codebase serves an unlimited number of municipalities. A municipality is configured entirely through data and an Administration UI — **there is no municipality-specific code, anywhere, ever.**

- **Target customers:** French municipalities and communities of municipalities, 2,000–100,000 inhabitants.
- **Core promise:** replace paper, Excel, duplicated data and manual reporting with one reliable, configurable platform.
- **Golden rule:** never think "Créteil", always think "Any municipality". Créteil is just one configuration among many.

> `stan` is the working codename for the platform. It is a placeholder for the product's future commercial name and appears only as a package namespace (`@stan/*`) and repo name — never as user-facing, tenant-facing, or business copy.

---

## Status

**Phase 0 — Design & Documentation.** No business code exists yet. This repository currently contains only the design of the system. See [docs/roadmap.md](docs/roadmap.md) for the phase plan.

The order of work is deliberate and non-negotiable:

1. **Phase 0** — Analysis, architecture, documentation (this phase).
2. **Phase 1** — Database design (ERD, entities, relationships, Prisma schema) — **validated before any code**.
3. **Phase 2** — Project initialization (monorepo, tooling, CI/CD).
4. **Phase 3+** — Feature delivery, one bounded domain at a time.

---

## Documentation index

Everything about how this system is built lives in [`/docs`](docs). Start here:

| Document | What it covers |
| --- | --- |
| [architecture.md](docs/architecture.md) | System architecture, layers, data flow, boundaries |
| [folder-structure.md](docs/folder-structure.md) | Monorepo layout, feature-module anatomy, import aliases |
| [multi-tenancy.md](docs/multi-tenancy.md) | Tenant isolation model and enforcement (the most important doc) |
| [database-philosophy.md](docs/database-philosophy.md) | Modelling rules, base columns, soft delete, IDs |
| [authentication.md](docs/authentication.md) | Supabase Auth, sessions, identity |
| [authorization-rbac.md](docs/authorization-rbac.md) | Roles, permissions, per-municipality RBAC |
| [security.md](docs/security.md) | Threat model, GDPR, secrets, rate limiting, CSRF |
| [audit.md](docs/audit.md) | Audit trail, what we log, immutability |
| [configuration-strategy.md](docs/configuration-strategy.md) | How everything becomes data-driven |
| [municipality-initialization.md](docs/municipality-initialization.md) | Installing a municipality from one file |
| [import-export.md](docs/import-export.md) | Bulk import/export, formats, validation |
| [coding-conventions.md](docs/coding-conventions.md) | TypeScript, naming, patterns, DoD |
| [testing.md](docs/testing.md) | Test pyramid, tooling, coverage policy |
| [ci-cd.md](docs/ci-cd.md) | GitHub Actions pipeline, quality gates |
| [deployment.md](docs/deployment.md) | Vercel, environments, EU residency, migrations |
| [roadmap.md](docs/roadmap.md) | Phased delivery plan |
| [glossary.md](docs/glossary.md) | Domain vocabulary (FR municipal context) |
| [adr/](docs/adr) | Architecture Decision Records |

The single source of truth for **product intent** is [Context.md](Context.md). This README and `/docs` describe **how** we honour it. If a doc ever contradicts `Context.md`, `Context.md` wins and the doc is a bug.

---

## Technology stack

| Layer | Choice |
| --- | --- |
| Framework | Next.js (App Router), React, TypeScript (strict) |
| UI | TailwindCSS, shadcn/ui, Framer Motion, Recharts, Leaflet |
| Forms & data | React Hook Form, Zod, TanStack Query, TanStack Table |
| Backend | Next.js Server Actions + Route Handlers over a framework-agnostic service/repository layer |
| ORM | Prisma |
| Database | Supabase PostgreSQL (EU region) |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| Monorepo | Turborepo + pnpm workspaces |
| Hosting | Vercel (EU functions) |
| CI/CD | GitHub Actions |

Full rationale for each choice is captured in the [ADRs](docs/adr).

---

## Architectural non-negotiables

These are enforced by review and by tooling. Violating one is a blocking defect:

1. **No municipality-specific code.** No hardcoded names, structures, roles, schedules, email domains, CAF values, colours or logos. Everything comes from the database.
2. **Tenant isolation is mandatory and enforced in depth.** Every tenant query is scoped by `municipalityId` at the application layer *and* protected by Postgres Row-Level Security. See [multi-tenancy.md](docs/multi-tenancy.md).
3. **Business logic lives in services, not in framework glue.** Server Actions and Route Handlers are thin adapters.
4. **Validation everywhere.** Every external input (form, action, route, import file) is validated with Zod at the boundary.
5. **Everything auditable and soft-deletable where it matters.** See [audit.md](docs/audit.md) and [database-philosophy.md](docs/database-philosophy.md).
6. **Production-ready only.** No `TODO`, no dead code, no commented-out code, no placeholder implementations. The app is always runnable.
7. **EU data residency.** Personal data of French residents stays in the EU. See [security.md](docs/security.md).

---

## Getting started

> Not applicable yet — Phase 0 produces documentation only. The initialization procedure (install, env, database, dev server) will be written into this section during Phase 2 and kept accurate from that point on.
