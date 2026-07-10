# ADR-0001 — Modular monolith in a Turborepo monorepo

**Status:** Accepted (Phase 0)

## Context

Stan is a greenfield multi-tenant SaaS. We need a structure that ships fast now (single agent-facing back-office) yet scales to a "reference SaaS" that will plausibly grow additional surfaces later (a parent/family portal, a mobile app, background workers, a public API). The founder's brief showed an `apps/` + `packages/` layout. We must avoid two failure modes: (a) a tangled single app where everything imports everything, and (b) premature multi-app/microservice complexity that slows early delivery.

## Decision

Build a **modular monolith** deployed as **one Next.js app**, inside a **Turborepo + pnpm monorepo** with real shared `packages/*`. Start with a single app (`apps/web`) and extract shared code into versioned packages (`db`, `core`, `config`, `validation`, `domain`, `ui`, `auth`). Organize application code by **feature module** with a uniform internal shape and a public `index.ts` surface. Enforce dependency boundaries with ESLint.

Additional apps (`apps/parent-portal`, `apps/mobile`, workers) are added only when the roadmap requires them — the monorepo makes that additive, not a restructure.

## Consequences

- **Positive:** fast to build and reason about; shared code is a real, enforced boundary (no "import everything" rot); a second app can be added without re-architecting; modules can later be extracted to packages/services because dependencies point inward.
- **Positive:** one deploy, one mental model, one migration path early on.
- **Negative / cost:** monorepo tooling (Turborepo, workspace wiring) has upfront setup and a learning curve; discipline is required to keep module boundaries clean — mitigated by lint-enforced boundaries.
- **Negative:** a modular monolith shares a runtime, so one module can't scale independently *yet* — accepted; the extraction path exists when needed.

## Alternatives considered

- **Single plain Next.js app, no monorepo:** simplest start, but no enforced shared-code boundary and a painful migration when a second app appears. Rejected for a product explicitly aiming at multiple surfaces.
- **Full monorepo with multiple apps now:** premature; we'd maintain half-built apps before the core exists. Rejected until a parent portal / mobile app is an actual priority.
- **Microservices:** unjustified complexity at our scale and stage; distributes a domain that isn't yet understood. Rejected.

Chosen middle path: monorepo-ready structure, one app today.
