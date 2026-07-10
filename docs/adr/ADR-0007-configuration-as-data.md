# ADR-0007 — Configuration as data; municipality-as-file

**Status:** Accepted (Phase 0)

## Context

Stan's core promise: **one codebase, only the data changes**; a municipality must be configurable with **no development**, and installable from **one file** (Context.md). The legacy app hardcoded municipality specifics in `/config`, `/acces`, `/outils_maintenance`. We must guarantee no municipality value ever enters the source code, while keeping configuration integrity, history, and easy onboarding.

## Decision

- Treat **anything that could differ between municipalities as tenant data**, stored as **normalized relational tables** (structures, opening hours, pricing, roles, calendars…), tenant-scoped and audited — not as blobs or code.
- Separate three config tiers: **platform config** (code/seed), **tenant config** (DB, editable in Administration at runtime), **secrets** (encrypted env).
- Code never inlines a municipality value; it reads via a **configuration service** with per-tenant caching. Modules/features are **gated by config**, resolved from data.
- Branding/theming (name, logo, colours, banner) is tenant config driving the UI theme at runtime — no build-time constants.
- A municipality is **installable/updatable from one YAML/JSON file** through an atomic, idempotent, dry-run-able **provisioning pipeline** (schema in `@stan/config`). Optional starting templates ship as data, never code.
- All config is **Zod-validated** on write and on import; temporal config (calendars, hours, pricing) is validity-bound so history is preserved.

## Consequences

- **Positive:** the same build serves every customer; onboarding hundreds of municipalities becomes a repeatable operation; a tenant's config is versionable, reviewable, reproducible; configurability is a first-class product surface (Administration).
- **Positive:** normalized config gives integrity constraints, queryability, and audit — superior to config blobs.
- **Negative / cost:** more modelling up front (each configurable concept is a real table + Administration UI) than hardcoding — accepted; it is the product's core value. A key/value `settings` table absorbs the genuinely free-form remainder (Zod-typed).
- **Negative:** provisioning + Administration are non-trivial subsystems built early (Phase 3) — accepted, sequenced deliberately.

## Alternatives considered

- **Hardcoded per-municipality builds/branches:** violates the entire thesis; unmaintainable at scale. Rejected absolutely.
- **Single JSON/YAML config blob per tenant in one column:** easy to import, but no integrity, no history, poor queryability, awkward partial edits. Rejected for structured domains; retained only for misc settings.
- **Env-var-driven per-tenant config:** doesn't scale to hundreds of tenants and mixes secrets with business config. Rejected.

See [configuration-strategy.md](../configuration-strategy.md) and [municipality-initialization.md](../municipality-initialization.md).
