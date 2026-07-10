# Architecture Decision Records (ADR)

An ADR captures **one significant architectural decision**: its context, the decision, and its consequences. ADRs are immutable once accepted — we don't edit history; we supersede an ADR with a new one.

## Format

Each ADR follows: **Status** · **Context** · **Decision** · **Consequences** · **Alternatives considered**.

Statuses: `Proposed` → `Accepted` → (later) `Superseded by ADR-XXXX` / `Deprecated`.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](ADR-0001-modular-monolith-monorepo.md) | Modular monolith in a Turborepo monorepo | Accepted |
| [0002](ADR-0002-multi-tenancy-strategy.md) | Multi-tenancy: shared schema + row scoping + RLS | Accepted |
| [0003](ADR-0003-database-conventions.md) | Database conventions: UUID keys, base columns, soft delete | Accepted |
| [0004](ADR-0004-auth-strategy.md) | Authentication via Supabase Auth | Accepted |
| [0005](ADR-0005-rbac-model.md) | Permission-based RBAC with per-municipality roles | Accepted |
| [0006](ADR-0006-tech-stack.md) | Technology stack | Accepted |
| [0007](ADR-0007-configuration-as-data.md) | Configuration as data; municipality-as-file | Accepted |
| [0008](ADR-0008-server-actions-service-layer.md) | Server Actions/Route Handlers over a service layer | Accepted |

## When to write one

Write an ADR when a decision is hard to reverse, affects multiple modules, or a future engineer would ask "why is it done this way?". Small, local choices don't need one.
