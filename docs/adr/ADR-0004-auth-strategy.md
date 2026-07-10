# ADR-0004 — Authentication via Supabase Auth

**Status:** Accepted (Phase 0)

## Context

We need secure authentication for municipal agents, with EU residency, standard tokens, integration with Postgres/RLS, and support for a user belonging to multiple municipalities. Rolling our own auth (password hashing, token rotation, email flows) is a large, security-critical undertaking we should avoid.

## Decision

Use **Supabase Auth** as the identity provider. Each human is a Supabase auth user (`uuid`); our application `User` row shares the same `id` (1:1) and holds profile data only — **credentials never live in our tables**. Sessions use Supabase's JWT + rotating refresh token stored in **http-only, secure, `SameSite` cookies**, refreshed in Next.js middleware. The JWT establishes **identity only**; **authorization and tenant scoping are resolved server-side against the database every request** via `TenantContext`. Every backend entry point authenticates independently. Support email/password and magic-link now; SSO/OIDC and MFA are enabled per municipality when needed (Supabase-native).

## Consequences

- **Positive:** we don't build/maintain security-critical auth primitives; EU-region, one vendor with the DB; standard JWTs; smooth path to MFA/SSO.
- **Positive:** identity/authorization separation keeps multi-municipality membership clean and makes revocation immediate (DB is authoritative).
- **Negative / cost:** coupling to Supabase Auth — mitigated because our app models identity as a plain `User` row keyed by the auth `uuid`; swapping providers later means re-issuing identities, not reshaping the domain.
- **Negative:** Prisma connects with a privileged role, so we can't rely on Supabase's default `auth.uid()` RLS for the Prisma path — handled by setting `app.current_municipality` per transaction (see ADR-0002).

## Alternatives considered

- **Custom auth (Lucia/NextAuth + our own user store):** more control, but we own password hashing, token rotation, email flows, and their security bugs. Rejected — not our core value.
- **Auth0/Clerk:** capable, but adds a third vendor and (for some) non-EU data-path questions; Supabase Auth is already in our stack and EU-region. Rejected for now.

See [authentication.md](../authentication.md).
