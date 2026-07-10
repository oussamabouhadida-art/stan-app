# Testing strategy

Tests exist to let us ship quickly **without** breaking tenant isolation, authorization, or business rules. We test what matters, at the level where it's cheapest and most meaningful.

Related: [ci-cd.md](ci-cd.md), [multi-tenancy.md](multi-tenancy.md).

---

## 1. The pyramid (our proportions)

```
        ┌───────────────┐
        │   E2E (few)   │   Critical user journeys, real browser
        ├───────────────┤
        │ Integration   │   Services + repositories against a real Postgres,
        │  (moderate)   │   RLS, isolation, transactions
        ├───────────────┤
        │  Unit (many)  │   Services (mocked repos), domain logic, Zod schemas,
        │               │   utils, components
        └───────────────┘
```

Most value comes from the **unit** layer (fast, precise) and a solid **integration** layer that proves isolation and DB behaviour. E2E is deliberately small — a few high-value journeys, because it's slow and brittle.

---

## 2. Tooling

| Layer | Tool |
| --- | --- |
| Unit / integration | **Vitest** (fast, TS-native, ESM) |
| React components | **React Testing Library** + Vitest |
| E2E | **Playwright** (real browser, tablet viewport) |
| DB for integration | Ephemeral **Postgres** (Docker locally, service container in CI) with real migrations + RLS |
| Mocks/factories | Typed test factories per domain; no ad-hoc fixtures |
| API mocking (client) | **MSW** where needed |

We test against a **real Postgres** for integration, never a fake, because RLS and constraints are part of the behaviour we must verify.

---

## 3. What we test at each layer

### Unit (many)
- **Domain logic**: pure functions, invariants, calculations (pricing, age brackets, calendar resolution).
- **Services**: business orchestration with mocked repositories — permission checks (`assertCan` denies without the permission), invariant enforcement, audit emission, error paths.
- **Zod schemas**: accept valid, reject invalid, including edge cases and FR-specific primitives.
- **Components**: rendering, accessibility (roles/labels), permission-gated visibility, form validation UX.

### Integration (moderate)
- **Repositories** against real Postgres: correct queries, constraints, soft-delete exclusion, transactions.
- **Tenant isolation** (mandatory — see §4).
- **RLS policies**: enforced at the DB level.
- **Provisioning & import pipelines**: a config file / CSV in → correct, atomic, idempotent DB state out.

### E2E (few)
- Login → pick municipality → land on dashboard.
- Record attendance for a session end-to-end.
- Edit a configuration value in Administration and see it reflected.
- Install a municipality from a file (super-admin) and verify it's usable.

---

## 4. Isolation tests are mandatory and blocking

Because a tenancy bug is a data breach, these are **required** and gate all merges (see [multi-tenancy.md](multi-tenancy.md) §7):

- Tenant-scoped Prisma extension: injects `municipalityId`; unscoped tenant query throws; foreign `municipalityId` override throws.
- RLS: with tenant A's context, tenant B's rows are invisible and unwritable.
- Cross-tenant probe: authenticated as A, every attempt (service + raw) to reach B's data fails.

Any code that adds a tenant-scoped table or touches the isolation path must extend these tests.

---

## 5. Conventions

- Tests are **co-located** with the code (`*.test.ts(x)` next to the file).
- **Arrange–Act–Assert**; one behaviour per test; descriptive names (`denies attendance.write without permission`).
- **Typed factories** build valid domain objects; tests override only what's relevant.
- **No network, no real Supabase** in unit tests; integration uses the ephemeral DB. E2E uses a seeded test tenant.
- **Deterministic**: no reliance on wall-clock/timezone/order; inject clocks; seed randomness.
- Tests contain **no real PII** — synthetic data only.

---

## 6. Coverage policy

- Coverage is a **signal, not a target to game**. We require meaningful coverage of **services, domain logic, and the isolation/auth paths** — these are non-negotiable.
- CI enforces a coverage floor on `services/` and `domain/` and 100% on the tenancy/auth core. UI coverage is expected but not chased to arbitrary percentages.
- A PR that adds a protected operation without a permission-denial test does not merge.

---

## 7. When to write which test

| You're adding… | Write… |
| --- | --- |
| A business rule/service | Unit tests (happy + denial + invariant + error paths) |
| A Prisma query | Integration test against real DB |
| A tenant-scoped table | Extend isolation + RLS tests |
| A Zod schema | Unit tests (valid/invalid) |
| A form/component | RTL test (render, a11y, validation UX, permission gating) |
| A critical journey | One Playwright E2E |
| An import/provisioning path | Integration test (atomic + idempotent + validation-failure) |

---

## 8. Non-goals

- We don't unit-test framework glue (thin adapters) beyond ensuring they call the right service and translate errors.
- We don't pursue 100% line coverage for its own sake.
- We don't test third-party libraries; we test **our** use of them.
