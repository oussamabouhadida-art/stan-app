# Architecture

This document describes the system architecture of Stan: its layers, boundaries, data flow, and the rules that keep it maintainable at scale. It is the map; the other docs are the territory.

---

## 1. Architectural goals

Ranked. When two goals conflict, the higher one wins.

1. **Tenant safety** — one municipality can never read or write another's data. Non-negotiable.
2. **Maintainability** — a change to a domain is local to that domain. New engineers become productive fast.
3. **Configurability** — behaviour changes with data, not code.
4. **Correctness** — invalid states are unrepresentable; inputs are validated at every boundary.
5. **Performance** — fast on a tablet on municipal wifi.
6. **Velocity** — ship incrementally without accumulating debt.

---

## 2. High-level shape

Stan is a **modular monolith** deployed as a single Next.js application on Vercel, backed by Supabase (PostgreSQL, Auth, Storage). It is a monolith by deployment and a set of well-separated **feature modules** by code. We do not start with microservices; the modular boundaries make extraction possible later if a module ever needs its own lifecycle.

```
                         ┌─────────────────────────────────────────┐
        Browser /        │              Next.js (apps/web)          │
        Tablet (agent)   │                                          │
   ────────────────────► │  App Router (RSC)  ─ UI / pages / layout │
                         │        │                                 │
                         │        ▼                                 │
                         │  Transport adapters                      │
                         │   • Server Actions                       │
                         │   • Route Handlers (REST/webhooks)       │
                         │        │                                 │
                         │        ▼                                 │
                         │  Application layer (services / use-cases)│
                         │        │                                 │
                         │        ▼                                 │
                         │  Domain layer (entities, rules, types)   │
                         │        │                                 │
                         │        ▼                                 │
                         │  Repository layer (Prisma)               │
                         └────────┼─────────────────────────────────┘
                                  │  tenant-scoped Prisma client
                                  ▼
                    ┌─────────────────────────────────────┐
                    │   Supabase (EU region)              │
                    │   • PostgreSQL  (+ Row-Level Sec.)  │
                    │   • Auth        (identity, sessions)│
                    │   • Storage     (documents, logos)  │
                    └─────────────────────────────────────┘
```

---

## 3. Layers

We apply Clean Architecture pragmatically. Dependencies point **inward**: outer layers know about inner layers, never the reverse.

### 3.1 Presentation (UI)
React Server Components and Client Components in `apps/web`. Renders state, captures intent, delegates every mutation and non-trivial query to a transport adapter. **Contains no business rules.** UI never imports Prisma or talks to the database directly.

### 3.2 Transport adapters
The only Next.js-aware backend code:
- **Server Actions** — the default for mutations and form submissions from our own UI.
- **Route Handlers** — REST endpoints for external integrations, webhooks (Supabase, payment/CAF later), file up/download, and any public API.

An adapter does exactly four things: authenticate, resolve tenant context, validate input (Zod), then call **one** application service. It returns a typed result or a typed error. It contains no business logic. This keeps us portable: a future mobile app or public API reuses the same services.

### 3.3 Application layer (services / use-cases)
The heart of the backend. A service orchestrates a single business operation ("register a child", "record attendance for a session", "import a municipality"). It:
- receives already-validated, typed input and an explicit **`TenantContext`** (who, which municipality, which permissions);
- enforces **authorization** (does this actor's role permit this operation in this municipality?);
- enforces **business invariants** (a child can't be enrolled in an activity outside their age bracket);
- coordinates repositories and other services within a transaction where needed;
- emits **audit events** and **domain events** (notifications, emails) as side effects.

Services are framework-agnostic plain TypeScript. They are the primary unit of unit-testing.

### 3.4 Domain layer
Entities, value objects, domain types, and pure business rules that don't need I/O. Small and dependency-free. This is where "a school year", "an opening-hours calendar", "a pricing tier" live as types and pure functions. Shared cross-module domain types live in `@stan/domain` (or `@stan/types`); module-local ones stay in the module.

### 3.5 Repository layer
The only code that touches Prisma. Repositories expose intention-revealing methods (`childRepository.findEnrollableForSession(...)`) rather than leaking query builders. **Every repository method operates through the tenant-scoped Prisma client** (see §5). Repositories return domain-shaped data, not raw Prisma rows leaking into services where it causes coupling.

### 3.6 Infrastructure
Cross-cutting concerns: the Prisma client factory, Supabase clients, the audit writer, the config loader, the email/notification providers, file storage, rate limiting. Provided to services via explicit dependencies, never imported ad hoc deep in business code.

---

## 4. Dependency rule (enforced)

```
UI ─► Transport ─► Application ─► Domain
                        │
                        └─► Repository ─► Prisma ─► DB
```

- UI **must not** import Prisma, repositories, or Supabase server clients.
- Application **must not** import Next.js (`next/*`) or React.
- Domain **must not** import anything with I/O.
- Repositories are the **only** importers of `@prisma/client`.

These rules are enforced with ESLint boundary rules (`eslint-plugin-boundaries` / `no-restricted-imports`) in CI, not just by convention. See [ci-cd.md](ci-cd.md).

---

## 5. The tenant-scoped data path

This is the single most important mechanism in the system and is specified fully in [multi-tenancy.md](multi-tenancy.md). In summary:

- A request resolves a **`TenantContext`** early (from the authenticated Supabase session + the active membership).
- All data access goes through a **Prisma client extension** that injects `municipalityId` into every query on a tenant-scoped model and **refuses** to run an unscoped tenant query.
- Postgres **Row-Level Security** is enabled on every tenant table as an independent second wall. Even a bug in the app layer cannot cross tenants.

Two independent walls (application + database) is deliberate defense-in-depth.

---

## 6. Data flow examples

**Mutation (record attendance):**
`Client form → Server Action → [authenticate → resolve TenantContext → Zod validate] → AttendanceService.record() → [authorize: 'attendance.write' → check invariants → attendanceRepository.create() (tenant-scoped) → auditWriter.log() → notify] → typed result → UI revalidates (TanStack Query / router).`

**Configuration read (Administration → opening hours):**
`RSC page → OpeningHoursService.listForStructure() → openingHoursRepository.find() (tenant-scoped) → rendered.` No hardcoded schedule anywhere; all values come from the tenant's configuration.

**Municipality install (import one file):**
`Admin uploads municipality.yaml → Route Handler → [authenticate super-admin → Zod-validate parsed file against the municipality schema] → MunicipalityProvisioningService.install() → creates municipality, structures, roles, permissions, calendars, programs, pricing… in a single transaction → audit.` See [municipality-initialization.md](municipality-initialization.md).

---

## 7. Frontend architecture

- **Server Components by default**; Client Components only where interactivity requires it (`"use client"` at the leaf, not the root).
- **Server state** (anything from the DB) is fetched in RSCs or via TanStack Query in client components. **Client/UI state** stays in React.
- **Forms**: React Hook Form + Zod resolver. The *same* Zod schema validates on the client (UX) and again in the Server Action (trust). Client validation is a convenience; server validation is the security boundary.
- **Design system**: shadcn/ui primitives composed into `@stan/ui`. No one-off component styling that can't be themed per municipality (colours, logo).
- **Tablet-first** responsive design; large touch targets; minimal clicks; offline-tolerant read patterns considered from the start.
- **Maps** via Leaflet (GIS: structures, neighborhoods, catchment). **Charts** via Recharts (dashboards, CAF indicators, statistics).

---

## 8. Cross-cutting concerns

| Concern | Where it lives | Doc |
| --- | --- | --- |
| Authentication | Supabase Auth + middleware + `TenantContext` | [authentication.md](authentication.md) |
| Authorization | Application layer, DB-backed RBAC | [authorization-rbac.md](authorization-rbac.md) |
| Tenant isolation | Prisma extension + Postgres RLS | [multi-tenancy.md](multi-tenancy.md) |
| Validation | Zod at every boundary | [coding-conventions.md](coding-conventions.md) |
| Audit | Infra `auditWriter`, called by services | [audit.md](audit.md) |
| Configuration | DB-backed, loaded via config service | [configuration-strategy.md](configuration-strategy.md) |
| Error handling | Typed `Result`/error objects; no throwing across the transport boundary for expected errors | [coding-conventions.md](coding-conventions.md) |
| Observability | Structured logging, Vercel + Supabase telemetry | [deployment.md](deployment.md) |

---

## 9. What we explicitly avoid

- **Microservices / premature distribution.** A modular monolith is faster to build and reason about at our scale. Boundaries keep the door open.
- **Schema-per-tenant / database-per-tenant.** Operationally unmanageable for hundreds of small tenants. See [ADR-0002](adr/ADR-0002-multi-tenancy-strategy.md).
- **Business logic in components or actions.** It becomes untestable and duplicated.
- **A generic "God" repository / anemic services.** Repositories are intention-revealing; services own the rules.
- **ORMs bypassed with raw SQL** except for deliberate, reviewed, performance-critical or RLS-policy code.

---

## 10. Evolution path

When (not if) a module needs independent scaling or a separate deploy cadence, the sequence is: extract its services + repositories into a `packages/*` package → put a thin API boundary in front → move it to its own runtime. Because dependencies already point inward and modules don't reach into each other's internals, this is refactoring, not rewriting. This is exactly why we started with a monorepo (`apps/` + `packages/`) even with a single app today.
