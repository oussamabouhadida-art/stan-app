# Authentication

How Stan proves *who* a request is. Authorization (what they may do) is in [authorization-rbac.md](authorization-rbac.md); tenant resolution is in [multi-tenancy.md](multi-tenancy.md).

Decision record: [ADR-0004](adr/ADR-0004-auth-strategy.md).

---

## 1. Identity provider: Supabase Auth

We use **Supabase Auth** as the identity provider. Rationale: it is part of our platform (one vendor, EU region), issues standard JWTs, integrates with Postgres/RLS, and handles the security-critical primitives (password hashing, token rotation, email flows) that we should never hand-roll.

- Every human is a **Supabase auth user** (`uuid`).
- Our application `User` row has the **same `id`** as the Supabase auth user (1:1). The `User` row holds application profile data (display name, locale, status); credentials live only in Supabase.
- We never store passwords. We never build our own session/token system.

---

## 2. Supported sign-in methods

| Method | When | Notes |
| --- | --- | --- |
| Email + password | Default for agents | Strong password policy enforced by Supabase config |
| Magic link / OTP email | Optional per municipality | Lowers friction for occasional users |
| SSO / OIDC (SAML) | Roadmap (larger municipalities, communautés) | Supabase supports it; wired when a customer needs it |

Method availability can be constrained per municipality via configuration — but the *mechanism* is always Supabase. No custom auth code.

---

## 3. Sessions

- Supabase issues a short-lived **access token (JWT)** and a rotating **refresh token**, stored in **http-only, secure, `SameSite=Lax` cookies** — never in `localStorage` (XSS-exfiltration risk).
- Token refresh happens in **Next.js middleware** on navigation, using the Supabase SSR helpers, so Server Components always see a fresh session.
- The JWT is the source of `userId`. It is **never** trusted for authorization or tenant scoping beyond identity — those are resolved server-side against the database on every request.

---

## 4. From session to `TenantContext`

Authentication yields only *identity*. Each request then resolves the full [`TenantContext`](multi-tenancy.md#4-tenantcontext):

```
Request
  → middleware: refresh Supabase session → userId (from JWT)
  → (auth guard) if no session → redirect to /login
  → read "active municipality" cookie (signed)
  → load Membership(userId, activeMunicipalityId) from DB   ← authoritative
       → if missing/revoked/suspended → force re-selection or 403
  → resolve Role + Permissions for that membership
  → build TenantContext { userId, municipalityId, membershipId, roleId, permissions, isSuperAdmin }
```

Key properties:
- The active municipality cookie is a *hint*; the **database membership is authoritative** and checked every request. A user removed from a municipality loses access on their next request even if the cookie persists.
- A user with **multiple memberships** picks the active municipality after login (a picker); switching re-resolves the whole context.
- A user with **one membership** is scoped to it automatically.

---

## 5. Route protection

- The App Router is split into **`(auth)`** (unauthenticated: login, callback, password reset) and **`(app)`** (authenticated shell). The `(app)` layout resolves `TenantContext` and provides it down the tree; unauthenticated access to `(app)` redirects to login.
- **Server Actions and Route Handlers re-verify authentication independently.** They never trust that "the page was protected" — every mutation authenticates and authorizes on its own. Middleware is a convenience and a first filter, not the security boundary.
- **Route Handlers for external integrations** (webhooks) authenticate by verifying provider signatures / shared secrets, not user sessions.

---

## 6. Platform super-admin

- Platform operators (us) are a small set of `User`s flagged `isSuperAdmin`, used for provisioning municipalities and support.
- Super-admin is **not** a tenant role and does not implicitly grant access to tenant business data. Any super-admin access to a specific municipality's data is an **explicit, audited, time-scoped** action ("support access"), logged in the audit trail. This protects tenant trust and GDPR posture.

---

## 7. Account lifecycle

- **Provisioning:** users are created during municipality install (see [municipality-initialization.md](municipality-initialization.md)) or invited from Administration. Invitation creates the Supabase user + `User` row + `Membership`, and sends a set-password/magic-link email.
- **Suspension:** a membership can be `suspended` (keeps history, blocks access) without deleting the user, who may still be active in another municipality.
- **Deactivation/erasure:** handled per GDPR in [security.md](security.md).

---

## 8. Security requirements (summary)

- Passwords: never stored by us; policy enforced in Supabase (length, breach checks where available).
- Tokens: http-only cookies, rotation, short access-token TTL.
- Every backend entry point authenticates independently.
- Failed-login and auth-event **rate limiting** (see [security.md](security.md)).
- Auth events (login, logout, municipality switch, super-admin access) are **audited** (see [audit.md](audit.md)).
- MFA/2FA is on the roadmap and supported by Supabase; enabled per municipality policy when required.
