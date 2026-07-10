# CI/CD

Continuous integration and delivery via **GitHub Actions** → **Vercel**. The pipeline is a quality gate: nothing that fails typecheck, lint, tests, or isolation checks reaches `main`, and nothing reaches production without passing preview.

Related: [testing.md](testing.md), [deployment.md](deployment.md).

---

## 1. Branching model

- `main` — always deployable, always green. Protected: no direct pushes, required status checks, required review.
- `feat/*`, `fix/*`, `chore/*` — short-lived branches; one PR each.
- Every PR gets a **Vercel Preview Deployment** (isolated URL) for manual/UAT review.
- Merge to `main` → **production deployment** (after gates). Releases are tagged.

---

## 2. Pipeline stages (on every PR)

```
1. Setup        checkout · pnpm install (cached) · Turbo cache restore
2. Validate     typecheck (tsc)  ·  lint (ESLint incl. boundary+security)  ·  format check (Prettier)
3. Test         unit (Vitest)  ·  integration (Vitest + Postgres service)  ·  ISOLATION tests
4. Build        turbo build (all packages + apps/web)
5. Migrations   prisma migrate diff / validate — schema and migrations in sync
6. Security     dependency audit (pnpm audit / Dependabot)  ·  secret scan
7. Preview      Vercel preview deploy (automatic)
8. (main only)  Vercel production deploy + prisma migrate deploy (gated)
```

- **Turborepo caching** makes CI fast: only affected packages/tasks re-run. Remote cache shared across CI and local.
- **Fail fast**: stages 2–6 must all pass. A red check blocks merge (branch protection).
- **Isolation tests** (stage 3) are a hard gate — a tenancy regression can never merge.

---

## 3. Quality gates (branch protection on `main`)

Required to merge:
- ✅ Typecheck
- ✅ Lint (incl. architecture boundary rules + security rules)
- ✅ Format check
- ✅ Unit + integration + **isolation** tests
- ✅ Build
- ✅ Prisma migration validation
- ✅ Dependency audit (no high/critical unresolved)
- ✅ At least one approving review
- ✅ Up-to-date with `main`

---

## 4. Database migrations in the pipeline

- Migrations are **generated and committed** with the code that needs them (`packages/db/migrations`). CI verifies the schema and migrations are in sync (`prisma migrate diff`) — a drift fails the build.
- On production deploy, `prisma migrate deploy` runs against the production DB **before** the new app version serves traffic, in a controlled step.
- Migrations are written to be **backward-compatible** (expand/contract pattern) so a deploy never breaks the currently-running version. Destructive changes are split across releases. Details in [deployment.md](deployment.md).

---

## 5. Environments & secrets

| Environment | Trigger | Database | Purpose |
| --- | --- | --- | --- |
| Preview | every PR | isolated preview/branch DB | review, UAT |
| Production | merge to `main` | production Supabase (EU) | live |

- Secrets are **Vercel encrypted env vars** and **GitHub Actions secrets** — never in the repo. CI uses least-privilege tokens.
- `.env.example` documents required variables; real values live only in the secret stores (see [security.md](security.md)).

---

## 6. Local pre-commit gates

To keep CI green and feedback fast, the same checks run locally:

- **Husky** git hooks + **lint-staged**: on commit, run ESLint + Prettier on staged files and typecheck affected packages.
- **commitlint**: enforce Conventional Commits.
- Fast unit tests can run pre-push. The full suite runs in CI.

Local hooks prevent obvious failures from ever reaching CI; CI remains the source of truth.

---

## 7. Release & rollback

- **Releases** are the production deployments from `main`, tagged (SemVer or date-based) with generated release notes from Conventional Commits.
- **Rollback:** Vercel instant rollback to a previous deployment. Because migrations are backward-compatible (expand/contract), rolling back the app doesn't corrupt data; a forward-fix migration handles the contract step. The rollback procedure is documented in [deployment.md](deployment.md).

---

## 8. Observability of the pipeline

- CI status is visible on every PR; failures link to logs.
- Deployment status and preview URLs are posted back to the PR.
- Flaky tests are quarantined and fixed, not ignored — a flaky isolation/auth test is treated as a real bug.

---

## 9. Principles

1. **Green `main` always.** If it's not deployable, it doesn't merge.
2. **Every gate is automated.** Humans review design and correctness; machines enforce the mechanical rules.
3. **Fast feedback.** Caching + affected-only builds keep the loop tight.
4. **Isolation and security gates are non-negotiable** and cannot be skipped to "unblock" a merge.
