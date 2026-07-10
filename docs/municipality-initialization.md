# Municipality initialization

> A municipality must be installable from **one configuration file** (YAML or JSON). Importing it fully initializes the municipality. (Context.md, *Municipality Configuration*.)

This document specifies how a new tenant goes from nothing to fully operational via a single, validated file — with zero code changes.

Related: [configuration-strategy.md](configuration-strategy.md), [import-export.md](import-export.md), [multi-tenancy.md](multi-tenancy.md).

---

## 1. Goal

Onboarding a municipality is an **operation**, not a development task. Given `municipality.yaml`, the platform creates the tenant and every dependent record atomically, then the municipality is ready to use. The same mechanism supports **updating** an existing municipality's config (idempotent upsert) and **seeding demo/test tenants**.

---

## 2. What one file describes

A single config file describes the whole tenant (Context.md):

- **Identity** — name, legal identifiers (SIRET/INSEE), address, contacts, logo, colours, banner, locale, timezone.
- **Structures** — schools, leisure centres, youth centres, holiday centres, with codes, addresses, capacities, geo-coordinates.
- **Opening hours** — per structure, per period.
- **School calendar** — school year, zone (A/B/C), holiday periods, public holidays.
- **Programs / workshops / activities** — the offer.
- **Pricing** — tiers, rules.
- **CAF settings** — indicators and rules the municipality reports on.
- **Access model** — roles and their permissions; managers and animators (users) with their roles.
- **Email domains** — allowed domains.
- **Modules** — which business domains are enabled.
- **Settings** — remaining tenant preferences.

The authoritative schema is defined in `@stan/config` and documented in [config/municipality.schema.md](config/municipality.schema.md); an annotated example is [config/municipality.example.yaml](config/municipality.example.yaml).

---

## 3. The provisioning pipeline

```
municipality.(yaml|json)
   │
   1. Parse            → YAML/JSON → JS object            (@stan/config)
   │
   2. Validate         → Zod schema (structural + semantic invariants)
   │                     · fail fast with a precise, line-referenced error report
   │
   3. Plan             → resolve into an ordered set of upserts; compute a dry-run diff
   │                     · idempotent: keyed by stable natural keys (structure code, role name…)
   │
   4. Authorize        → require municipality.provision (super-admin)
   │
   5. Execute (atomic) → single DB transaction:
   │                     municipality → roles → permissions map → structures →
   │                     calendars/holidays → opening hours → programs → pricing →
   │                     CAF settings → email domains → users + memberships → settings
   │
   6. Audit            → record the install/update with before/after diff
   │
   7. Report           → summary: created/updated/skipped counts, warnings
```

Key properties:
- **Atomic:** the whole install succeeds or nothing is written. A partially-provisioned tenant can never exist.
- **Idempotent:** re-running the same file updates in place (upsert by natural keys) rather than duplicating. This makes config a reproducible artifact.
- **Dry-run first:** step 3 can produce a diff without executing, so operators preview exactly what will change.
- **Validated before touching the DB:** an invalid file is rejected in step 2 with actionable errors; nothing is half-applied.

---

## 4. Ordering & dependencies

The pipeline respects dependency order so foreign keys always resolve:

1. `Municipality` (the tenant root).
2. `Permission` mapping (from the global catalog) → `Role`s → `RolePermission`s.
3. `Structure`s (needed by hours, programs, memberships).
4. `SchoolYear` → holiday periods, public holidays → `OpeningHours`.
5. `Program`/`Activity` → `Pricing`.
6. CAF settings.
7. Email domains, settings.
8. `User`s + `Membership`s (reference roles + structures). Users are created in Supabase Auth and receive an invitation/set-password email.

Users are provisioned **without plaintext passwords** — the file references people by email + role; the system creates the Supabase identity and sends a secure onboarding email (see [authentication.md](authentication.md)).

---

## 5. Interfaces

Two ways to run provisioning, same pipeline underneath:

- **Administration / platform UI** — a super-admin uploads a file, previews the dry-run diff, confirms, and watches the report. This is the primary path.
- **Script / CLI** (`scripts/provision-municipality`) — for automation and CI seeding of demo tenants. Reuses the exact same `MunicipalityProvisioningService`; no separate logic.

Both go through the same Route Handler-less service to guarantee identical behaviour and validation.

---

## 6. Updating a municipality

- The same file, re-imported, performs an **idempotent update**: it upserts changed rows and reports what changed. Deletions are **never implicit** — a structure removed from the file is *not* auto-deleted (that would risk orphaning operational data). Removing entities is an explicit, audited Administration action.
- Config edits made in the Administration UI and file-based updates converge on the same tables; the file is one way to author config, the UI another.

---

## 7. Failure handling

- **Validation failure:** precise report (which field, which entity, why), no DB writes.
- **Execution failure:** transaction rolls back entirely; the tenant is left exactly as before; the error is audited.
- **Partial data quality warnings** (e.g. a structure with no opening hours) are surfaced as non-blocking warnings in the report, not silent.

---

## 8. Why this design

- It makes **onboarding hundreds of municipalities** a repeatable, low-risk operation — the commercial thesis of Context.md.
- Config-as-file makes a tenant's setup **versionable, reviewable, and reproducible** (a municipality's config can live in a git repo, be diffed, be restored).
- Idempotent + atomic provisioning means installs are safe to retry and safe to automate.

---

## 9. Rules for engineers (enforced)

1. All provisioning goes through the single `MunicipalityProvisioningService` — UI and CLI share it.
2. Validate fully (Zod, structural + semantic) before any write.
3. Execute in one transaction; never leave a partial tenant.
4. Upsert by stable natural keys; never duplicate on re-import.
5. Never auto-delete on re-import; deletions are explicit and audited.
6. Never put a real password in a config file; create identities via Supabase + invitation.
7. Record the whole operation in the audit trail with a diff.
