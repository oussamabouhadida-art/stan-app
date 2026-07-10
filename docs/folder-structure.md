# Folder structure

Stan is a **Turborepo + pnpm** monorepo. Today it contains a single application (`apps/web`) and a set of shared packages. The monorepo shape exists so that shared code is a real, versioned boundary — and so a second app (parent portal, mobile, worker) can be added later without restructuring.

> This document is the target structure created in **Phase 2**. It is documented now so every later decision respects it.

---

## 1. Top level

```
stan-app/
├── apps/
│   └── web/                     # The Next.js application (agent back-office)
├── packages/
│   ├── db/                      # Prisma schema, client, migrations, seed
│   ├── config/                  # Municipality config schema + loader (Zod)
│   ├── validation/              # Shared Zod schemas & primitives
│   ├── domain/                  # Cross-module domain types & pure logic
│   ├── ui/                      # shadcn/ui-based design system
│   ├── auth/                    # Supabase client factories, TenantContext
│   ├── core/                    # Result types, errors, tenant Prisma extension
│   └── tsconfig/                # Shared tsconfig presets
├── docs/                        # All documentation (source of "how")
├── prisma/                      # (symlink/re-export) — schema owned by packages/db
├── scripts/                     # Repo tooling (import, codegen, checks)
├── .github/
│   └── workflows/               # CI/CD pipelines
├── Context.md                   # Source of truth for product intent
├── README.md
├── turbo.json
├── pnpm-workspace.yaml
├── package.json
└── tsconfig.json
```

**Why packages, not just folders:** a package boundary is enforced by the module system. `@stan/ui` cannot secretly import a service from `apps/web`; the dependency has to be declared. This prevents the "everything imports everything" rot that kills large frontends.

**Prisma location:** the schema, generated client, and migrations live in `packages/db` so every consumer imports `@stan/db`. A root `prisma/` exists only as the conventional home the tooling expects; it re-exports from `packages/db`.

---

## 2. Package responsibilities

| Package | Owns | May depend on | Never depends on |
| --- | --- | --- | --- |
| `@stan/db` | Prisma schema, migrations, generated client, tenant extension wiring | `@stan/core` | apps, ui |
| `@stan/core` | `Result`/error types, `TenantContext` type, Prisma tenant-scoping extension | — | apps, ui, next |
| `@stan/config` | Municipality config file schema (Zod), parser, YAML/JSON loader | `@stan/validation` | apps, ui |
| `@stan/validation` | Reusable Zod primitives (email, phone FR, postal code, SIRET…) | — | apps, ui |
| `@stan/domain` | Cross-cutting domain types & pure functions (school year, calendars, age brackets) | `@stan/validation` | apps, ui, db |
| `@stan/auth` | Supabase server/browser client factories, session → `TenantContext` resolution | `@stan/db`, `@stan/core` | ui |
| `@stan/ui` | Design-system components, theme provider (per-municipality theming) | — | apps, db, services |
| `@stan/tsconfig` | Base/next/node tsconfig presets | — | everything else |

The dependency direction is: **apps → packages**, and within packages, **ui/config/validation/domain → core**, with `db` and `auth` at the infrastructure edge. No cycles.

---

## 3. Inside `apps/web` — feature-based architecture

The application is organized by **business domain (feature module)**, not by technical type. You do not have a top-level `components/`, `services/`, `hooks/` with everything dumped in; each domain is a self-contained slice.

```
apps/web/
├── app/                              # Next.js App Router (routing only)
│   ├── (auth)/                       # Login, callback — unauthenticated
│   ├── (app)/                        # Authenticated shell (tenant required)
│   │   ├── layout.tsx                # Resolves TenantContext, nav, theme
│   │   ├── dashboard/
│   │   ├── families/
│   │   ├── children/
│   │   ├── youth/
│   │   ├── attendance/
│   │   ├── meals/
│   │   ├── trips/
│   │   ├── activities/
│   │   ├── administration/           # The heart: config, access, tools
│   │   └── ...
│   ├── api/                          # Route Handlers (webhooks, import, export)
│   └── layout.tsx / globals.css
│
├── modules/                          # ★ Feature modules (the real code)
│   ├── families/
│   │   ├── actions/                  # Server Actions (transport)
│   │   ├── services/                 # Use-cases (business logic)
│   │   ├── repositories/             # Prisma access (tenant-scoped)
│   │   ├── domain/                   # Types, invariants, pure logic
│   │   ├── schemas/                  # Zod schemas for this module
│   │   ├── components/               # UI specific to families
│   │   ├── hooks/                    # React hooks specific to families
│   │   └── index.ts                  # The module's public surface (barrel)
│   ├── children/
│   ├── attendance/
│   ├── administration/
│   └── ...                           # one folder per domain in Context.md
│
├── shared/                           # Cross-module app-level code
│   ├── components/                   # App shell, layout, generic widgets
│   ├── hooks/
│   ├── lib/                          # app-only helpers (formatters, etc.)
│   └── providers/                    # Query client, theme, toaster
│
├── middleware.ts                     # Auth/session refresh, tenant guard
├── next.config.ts
└── tsconfig.json
```

### 3.1 Module anatomy (the contract)

Every module follows the **same** internal shape. This uniformity is what makes the codebase navigable at scale:

- `actions/` — Server Actions. Thin. Authenticate → tenant → Zod validate → call one service.
- `services/` — business operations. Framework-agnostic. Unit-tested.
- `repositories/` — the only Prisma callers in the module. Always tenant-scoped.
- `domain/` — types, value objects, invariants, pure functions.
- `schemas/` — Zod schemas (shared client + server).
- `components/` / `hooks/` — UI belonging to this domain only.
- `index.ts` — the module's **public API**. Other modules import from `@/modules/x`, never from `@/modules/x/services/deep/file`.

### 3.2 Module boundaries

- A module may use another module **only through its `index.ts`** public surface.
- A module **must not** reach into another module's `repositories/` or `domain/` internals.
- Truly shared logic is promoted to a `packages/*` package, not copied.
- No module imports `apps/web/app/*`. Routing depends on modules, never the reverse.

---

## 4. Path aliases

Configured in `tsconfig` and honoured by ESLint, Next, and Vitest:

| Alias | Resolves to |
| --- | --- |
| `@/modules/*` | `apps/web/modules/*` |
| `@/shared/*` | `apps/web/shared/*` |
| `@/app/*` | `apps/web/app/*` |
| `@stan/db` | `packages/db` |
| `@stan/ui` | `packages/ui` |
| `@stan/core` | `packages/core` |
| `@stan/auth` | `packages/auth` |
| `@stan/config` | `packages/config` |
| `@stan/validation` | `packages/validation` |
| `@stan/domain` | `packages/domain` |

Relative `../../..` imports across module or package boundaries are disallowed by lint. Within a single file's own folder, short relative imports are fine.

---

## 5. Naming conventions (files & folders)

- **Folders:** `kebab-case` (`opening-hours/`, `passport-jeune/`).
- **React components:** `PascalCase.tsx` (`AttendanceSheet.tsx`).
- **Non-component TS:** `kebab-case.ts` (`attendance-service.ts`, `child-repository.ts`).
- **Zod schemas:** `*.schema.ts`. **Tests:** `*.test.ts` / `*.test.tsx` co-located next to the file under test.
- **Types:** `PascalCase`. **Functions/vars:** `camelCase`. **Constants/enums values:** `SCREAMING_SNAKE_CASE` only for true constants; enum *members* are `PascalCase`.
- One primary export per file where practical; barrels (`index.ts`) only at module/package public surfaces.

Full language conventions are in [coding-conventions.md](coding-conventions.md); database naming is in [database-philosophy.md](database-philosophy.md).

---

## 6. Where things go — quick reference

| I'm adding… | It goes in… |
| --- | --- |
| A new page/route | `apps/web/app/(app)/<domain>/` — thin, delegates to a module |
| A business rule | `apps/web/modules/<domain>/services/` (or `domain/` if pure) |
| A DB query | `apps/web/modules/<domain>/repositories/` |
| A form's validation | `apps/web/modules/<domain>/schemas/` |
| A reusable button/input | `@stan/ui` |
| A domain type used by 2+ modules | `@stan/domain` |
| A Zod primitive (FR phone, SIRET) | `@stan/validation` |
| A Prisma model | `@stan/db` schema |
| The municipality config format | `@stan/config` |
| A webhook / external endpoint | `apps/web/app/api/` |
| A one-off script | `scripts/` |
