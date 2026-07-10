# Coding conventions

The rules that keep the codebase consistent, safe, and reviewable. These are enforced by tooling (TypeScript, ESLint, Prettier) and by review. "Production-ready only" (Context.md) is the baseline, not the ceiling.

Related: [architecture.md](architecture.md), [folder-structure.md](folder-structure.md).

---

## 1. TypeScript

- **Strict mode, always.** `strict: true` plus `noUncheckedIndexedAccess`, `noImplicitOverride`, `exactOptionalPropertyTypes`, `noFallthroughCasesInSwitch`. No loosening per-file.
- **No `any`.** Use `unknown` at boundaries and narrow. `any` is a lint error; the rare justified exception needs an inline reason and reviewer sign-off.
- **No non-null `!` assertions** on values that could genuinely be null — narrow properly. Allowed only where the type system can't see an invariant that's locally obvious, with a comment.
- **Types over interfaces** for data shapes (consistency); interfaces for extensible contracts. Pick one per case and be consistent within a module.
- **Prefer `readonly`** and immutable data. Mutate locally, expose immutably.
- **Discriminated unions over booleans** for states (`{ status: 'idle' | 'loading' | 'error' }`), making invalid states unrepresentable.
- **`enum`s:** prefer union-of-literals or `as const` objects over TS `enum` in app code; DB-backed closed sets use Postgres enums / lookup tables (see [database-philosophy.md](database-philosophy.md)).

---

## 2. Validation (Zod) at every boundary

- Every external input — form, Server Action arg, Route Handler body/query, import file, webhook payload — is parsed with a **Zod schema at the boundary**. Unvalidated data never reaches a service.
- **Infer types from schemas** (`z.infer`) so the runtime check and the static type can't drift.
- The **same schema** validates client-side (RHF resolver, for UX) and server-side (for trust). Client validation is convenience; the server parse is the security boundary.
- Reusable primitives (FR phone, postal code, SIRET, email, IBAN) live in `@stan/validation`.

---

## 3. Error handling

- **Expected/domain errors** are returned as typed values, not thrown across the transport boundary. Services return a `Result<T, E>` (or throw typed domain errors that adapters translate). Transport adapters convert them into typed action results / HTTP responses.
- **Unexpected errors** (bugs, infra) throw, are caught at the boundary, logged with context, and returned to the client as a **generic** message — never a stack trace or internal detail (see [security.md](security.md)).
- Error types are explicit (`ForbiddenError`, `NotFoundError`, `ValidationError`, `ConflictError`), each mapping to a predictable client outcome.
- **Never swallow errors.** No empty `catch`. Either handle meaningfully or rethrow.

---

## 4. The service/repository/adapter contract

(See [architecture.md](architecture.md) for the layering.)

- **Server Actions / Route Handlers:** authenticate → resolve `TenantContext` → Zod-validate → call **one** service → return typed result. No business logic, no Prisma.
- **Services:** framework-agnostic. First line of a protected op is `assertCan(ctx, permission)`. Enforce invariants. Orchestrate repositories in transactions. Emit audit + events. No `next/*`, no React, no direct Prisma.
- **Repositories:** the only Prisma callers. Always use the **tenant-scoped** client. Intention-revealing method names. Return domain-shaped data.
- **Domain:** pure functions and types, no I/O.

---

## 5. Naming

| Kind | Convention | Example |
| --- | --- | --- |
| Component files | `PascalCase.tsx` | `AttendanceSheet.tsx` |
| Other TS files | `kebab-case.ts` | `attendance-service.ts` |
| Types / components | `PascalCase` | `AttendanceRecord` |
| Functions / variables | `camelCase` | `recordAttendance` |
| Booleans | `is/has/can` prefix | `isEnrolled`, `canEdit` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_UPLOAD_BYTES` |
| Zod schemas | `xSchema` in `*.schema.ts` | `childSchema` |
| Permission keys | `domain.action` | `attendance.write` |
| DB (tables/columns) | `snake_case` | see [database-philosophy.md](database-philosophy.md) |

- Names say **what/why**, not how. No abbreviations that aren't domain-standard. No French/English mixing in identifiers — **code identifiers are English**; user-facing strings are localized (FR default) via i18n, never hardcoded in components.

---

## 6. No magic values, no duplication

- **No magic numbers/strings.** Name them as constants or config. Business thresholds are config (per municipality) where they could vary.
- **No hardcoded municipality data** — ever (see [configuration-strategy.md](configuration-strategy.md)).
- **DRY across modules** by promoting shared logic to `packages/*`, not copy-paste. But prefer a little duplication over a wrong abstraction; extract when the third use appears and the shape is clear.

---

## 7. React / Next.js

- **Server Components by default;** `"use client"` only where interactivity requires it, pushed to leaves.
- **Data fetching:** server-side in RSCs or TanStack Query in client components. No fetching business data directly in components via Prisma.
- **Forms:** React Hook Form + Zod resolver; the same schema on the server.
- **Server state vs UI state:** never mirror server data into component state; derive it. Local UI state stays in React.
- **Accessibility is required**, not optional: semantic HTML, labels, keyboard navigation, focus management, ARIA where needed, colour-contrast (Context.md: *Everything accessible*). shadcn/ui primitives give us accessible defaults; don't regress them.
- **Performance:** memoize deliberately (not reflexively), lazy-load heavy client components (maps, charts), avoid waterfalls, use suspense/streaming.
- **Styling:** Tailwind utility classes; shared variants in `@stan/ui`. No inline colour literals for anything themable — theme tokens come from tenant config.

---

## 8. Comments & documentation

- Code should read clearly enough to need few comments. Comment the **why**, not the **what**.
- **No commented-out code. No dead code. No `TODO`/`FIXME`** left in committed code (Context.md). If something is deferred, it's a roadmap/issue item, not a comment.
- Public module surfaces (`index.ts`), services, and non-obvious domain rules get concise doc comments.
- Match the surrounding file's style, density, and idioms.

---

## 9. Definition of Done (per change)

A change is done only when **all** hold:

- [ ] Compiles (`tsc`) with no errors.
- [ ] Lints clean (ESLint, incl. boundary + security rules).
- [ ] Formatted (Prettier).
- [ ] Tests written and passing (unit for services/domain; integration where it crosses the DB; isolation tests for tenant-touching code). See [testing.md](testing.md).
- [ ] Inputs validated (Zod) at every new boundary.
- [ ] Permissions checked + tenant-scoped for every protected op.
- [ ] Auditable operations emit audit events.
- [ ] No hardcoded municipality data, no secrets, no dead code, no TODOs.
- [ ] App still runs; no broken build.
- [ ] Docs/ADR updated if a decision or contract changed.

---

## 10. Git & commits

- **Conventional Commits** (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`) with a scope where useful (`feat(attendance): …`).
- Small, meaningful, reviewable commits. Never commit generated secrets or `.env`.
- Work on branches; PRs pass CI (typecheck, lint, tests) before merge. Never commit or push without the user's request (per operating rules).
- Commit messages explain **why**, not just what.
