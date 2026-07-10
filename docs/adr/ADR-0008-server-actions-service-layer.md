# ADR-0008 — Server Actions/Route Handlers over a service layer

**Status:** Accepted (Phase 0)

## Context

Next.js offers **Server Actions** (great for our own forms/mutations) and **Route Handlers** (REST/webhooks). It's tempting to put business logic directly in them. But we anticipate additional consumers (parent portal, mobile, public API, background jobs) and we require testable, framework-independent business rules with consistent authorization, validation, and audit.

## Decision

Keep all business logic in a **framework-agnostic service layer** with a **repository layer** for data access. **Server Actions and Route Handlers are thin transport adapters** that do exactly: authenticate → resolve `TenantContext` → **Zod-validate** input → call **one** service → return a typed result/error. Adapters contain **no business logic** and never touch Prisma. Services enforce authorization (`assertCan`) and invariants, orchestrate repositories in transactions, and emit audit/events. Server Actions are the default for our UI; Route Handlers serve external integrations, webhooks, files, and any public API.

## Consequences

- **Positive:** business logic is unit-testable without Next.js; the same services power a future mobile app, public API, CLI (provisioning already reuses services), and jobs; authorization/validation/audit are enforced uniformly in one place; adapters stay trivial and swappable.
- **Positive:** clear layering makes the codebase navigable and the dependency rule enforceable by lint.
- **Negative / cost:** an extra layer of indirection vs "logic in the action" — a small, deliberate cost that pays off in testability and portability; mitigated by the uniform, thin adapter pattern.
- **Negative:** developers must resist putting "just a little logic" in an adapter — enforced by review and the DoD checklist.

## Alternatives considered

- **Logic directly in Server Actions/Route Handlers:** less indirection, but couples business rules to Next.js, duplicates logic across future consumers, and scatters authorization/validation. Rejected.
- **Full hexagonal/ports-and-adapters with interfaces everywhere:** maximal decoupling, but ceremony that outweighs benefit at our scale; we apply Clean Architecture pragmatically (services + repositories + explicit context) without over-abstracting. Chosen middle path.

See [architecture.md](../architecture.md) and [coding-conventions.md](../coding-conventions.md).
