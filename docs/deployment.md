# Deployment

How Stan runs in production: hosting, environments, database migrations, EU residency, backups, and operations.

Related: [ci-cd.md](ci-cd.md), [security.md](security.md).

---

## 1. Topology

| Concern | Platform |
| --- | --- |
| App hosting | **Vercel** (Next.js), **EU function regions** |
| Database | **Supabase PostgreSQL**, **EU region** |
| Auth | **Supabase Auth** (EU) |
| File storage | **Supabase Storage** (EU) |
| Source / CI | **GitHub** + GitHub Actions |
| Rate-limit / ephemeral state | Durable store (Supabase / Upstash Redis, EU) |

Everything that touches personal data is EU-region — a hard GDPR requirement (see [security.md](security.md) §2).

---

## 2. Environments

| Environment | Branch/trigger | Data | Notes |
| --- | --- | --- | --- |
| **Local** | developer machine | local Postgres (Docker) or personal Supabase branch | seeded demo tenant(s) |
| **Preview** | every PR | isolated preview DB (Supabase branch) | one URL per PR; UAT; auto-torn-down |
| **Production** | merge to `main` | production Supabase (EU) | live customers |

- Preview deployments use **branch databases** so a PR never touches production data and migrations are exercised safely before merge.
- Configuration differs only by **environment variables**, never by code.

---

## 3. Environment variables

- Managed in **Vercel** (per environment) and mirrored to **GitHub Actions secrets** for CI. Never committed.
- `.env.example` lists every required key with descriptions and no values. Typical keys: `DATABASE_URL` (pooled), `DIRECT_URL` (migrations), `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (server-only), rate-limit store creds.
- **Client vs server separation:** only `NEXT_PUBLIC_*` reach the browser. Service-role key and DB URLs are server-only and never bundled.
- **Rotation:** documented procedure — generate new key in Supabase → update Vercel + GitHub → redeploy → revoke old. No downtime for anon/JWT rotation with overlap.

---

## 4. Database connections

- **Pooled connection** (`DATABASE_URL` via Supabase/PgBouncer) for the serverless app — essential under Vercel's many short-lived function instances.
- **Direct connection** (`DIRECT_URL`) for migrations only.
- Prisma configured for serverless (connection limits, pooling) to avoid exhausting Postgres connections.

---

## 5. Migrations in production

Migrations follow the **expand/contract** pattern so deploys are zero-downtime and rollback-safe:

```
Expand   (release N)   add new nullable column / new table / new index — old code still works
Migrate data           backfill in a safe, batched step if needed
Switch   (release N)    new code reads/writes the new shape
Contract (release N+1)  remove the old column/constraint once no code uses it
```

- `prisma migrate deploy` runs in the production pipeline **before** the new version serves traffic ([ci-cd.md](ci-cd.md) §4).
- Never a destructive change and a code change in the same release. This is what makes **instant rollback** safe.
- Migrations are reviewed like code; large data migrations run as monitored background jobs.

---

## 6. Background jobs & scheduled work

Some work doesn't fit a request/response:
- **Long imports/exports**, provisioning of large municipalities.
- **Scheduled tasks**: retention purges, soft-delete cleanup, CAF/statistics rollups, notification digests.

These run via **Vercel Cron** (scheduled Route Handlers) and/or a queue-backed worker, all EU-region, all tenant-aware and audited. Long user-initiated jobs report progress and results (see [import-export.md](import-export.md)).

---

## 7. Backups & recovery

- **Supabase point-in-time recovery** (PITR) for the production database; retention set per compliance needs.
- Restore procedure documented and **periodically tested** — an untested backup is not a backup.
- Storage (documents) backed up per Supabase policy.
- Because data is tenant-scoped, we can reason about and, if ever needed, restore/extract a single tenant's data.

---

## 8. Observability

- **Application logs**: structured JSON, no PII/secrets, correlated by request id; shipped from Vercel.
- **Audit trail**: the authoritative "who did what" record (see [audit.md](audit.md)).
- **Metrics**: Vercel analytics (Core Web Vitals, function performance) + Supabase metrics (DB load, slow queries).
- **Alerting**: error-rate and latency alerts; DB connection saturation; failed migrations/deploys.
- **Health checks**: a lightweight endpoint for uptime monitoring.

---

## 9. Performance & scale

- **Tablet-first, field conditions**: optimize for real municipal networks — server components, streaming, minimal client JS, cached config reads, edge caching for static assets.
- **Scaling**: Vercel scales functions automatically; the DB is the bottleneck to watch — pooling, good indexes (see [database-philosophy.md](database-philosophy.md) §7), and query review keep it healthy as tenants grow.
- **Multi-tenant efficiency**: one shared, well-indexed schema serves all tenants; onboarding a municipality adds rows, not infrastructure.

---

## 10. Go-live checklist (per environment)

- [ ] EU region confirmed for app, DB, auth, storage.
- [ ] Env vars set per environment; secrets not in repo; client/server separation verified.
- [ ] Migrations applied via `migrate deploy`; schema in sync.
- [ ] RLS enabled/forced on every tenant table (isolation tests green).
- [ ] Security headers, rate limiting, CSRF protections active.
- [ ] Backups/PITR enabled; restore tested.
- [ ] Logging + alerting live; audit trail writing.
- [ ] Rollback procedure verified.
