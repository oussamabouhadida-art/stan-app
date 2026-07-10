# ADR-0006 — Technology stack

**Status:** Accepted (Phase 0)

## Context

The stack is largely prescribed by Context.md. This ADR records the choices, confirms their fit, and notes the few refinements we make as CTO. Constraints: EU data residency, tablet-first UX, multi-tenant SaaS, small team velocity, long-term maintainability.

## Decision

| Concern | Choice |
| --- | --- |
| Framework | **Next.js** (App Router), **React**, **TypeScript (strict)** |
| Styling / UI | **TailwindCSS**, **shadcn/ui**, **Framer Motion** |
| Data grids / charts / maps | **TanStack Table**, **Recharts**, **Leaflet** |
| Forms / validation / server-state | **React Hook Form**, **Zod**, **TanStack Query** |
| Backend | **Next.js Server Actions + Route Handlers** over a framework-agnostic **service/repository** layer (see ADR-0008) |
| ORM | **Prisma** |
| Database / Auth / Storage | **Supabase** PostgreSQL / Auth / Storage (**EU region**) |
| Monorepo | **Turborepo + pnpm** (see ADR-0001) |
| Hosting / CI | **Vercel** (EU functions) / **GitHub Actions** |
| Testing | **Vitest**, **React Testing Library**, **Playwright** |
| Quality | ESLint, Prettier, Husky, lint-staged, commitlint |

Refinements/clarifications made as CTO:
- **Zod** is elevated to the universal validation boundary (client + server + import).
- Business logic lives in a **service layer**, not in Server Actions (ADR-0008).
- **EU region** is mandatory across Supabase and Vercel (GDPR).

## Consequences

- **Positive:** cohesive, well-supported ecosystem; Supabase gives DB+Auth+Storage in one EU-region vendor; Vercel is first-class for Next.js; strong typing end-to-end (Prisma ↔ TS ↔ Zod).
- **Positive:** shadcn/ui gives accessible, themeable primitives supporting per-municipality branding.
- **Negative / cost:** coupling to Vercel + Supabase — accepted; both are standards-based (Postgres, Next.js) so the exit path is real if ever needed. Prisma + Supabase RLS needs care (ADR-0002/0004).
- **Negative:** Server Actions are relatively young — mitigated by keeping them thin over portable services (ADR-0008).

## Alternatives considered

- **Drizzle instead of Prisma:** lighter and closer to SQL, but Prisma's migrations, tooling, and the client-extension model (used for tenancy/soft-delete) fit our needs and the brief. Chosen: Prisma.
- **Dedicated backend (NestJS/Fastify) instead of Next server:** cleaner separation, but a second runtime and deploy target for little early gain; the service layer already gives us portability. Chosen: Next backend now, extractable later.
- **Self-hosted Postgres/auth:** more control, more ops burden and EU-compliance work; Supabase covers it managed. Chosen: Supabase.
