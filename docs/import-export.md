# Import / Export

Beyond municipality provisioning ([municipality-initialization.md](municipality-initialization.md)), municipalities need to move **operational data** in and out: onboarding existing families/children from spreadsheets, exchanging data with CAF/partners, producing reports, and exercising GDPR portability. This document defines the strategy so import/export is uniform, safe, and auditable across all domains.

---

## 1. Principles

1. **One import/export framework, many domains.** Each domain plugs into a shared pipeline rather than reinventing parsing/validation/reporting.
2. **Validated, never trusted.** Every imported row is Zod-validated; a bad row is reported, not silently dropped or blindly inserted.
3. **Tenant-scoped and permission-gated.** Imports/exports only ever touch the current municipality's data and require explicit permissions (`admin.tools`, plus domain permissions). Every run is audited.
4. **Deterministic & recoverable.** Imports are transactional per batch and produce a full report (created/updated/skipped/failed). Nothing half-applies.
5. **Portable formats.** Human-exchangeable formats first (CSV/XLSX for operational data; YAML/JSON for configuration), with stable schemas.

---

## 2. Formats

| Use case | Format(s) | Rationale |
| --- | --- | --- |
| Municipality configuration | **YAML / JSON** | Structured, reviewable, versionable ([municipality-initialization.md](municipality-initialization.md)) |
| Operational bulk data (families, children, enrolments) | **CSV / XLSX** | What municipalities already have from Excel |
| Reports / statistics export | **XLSX / CSV / PDF** | Office-friendly + printable |
| GDPR data portability | **JSON (+ human-readable PDF)** | Complete, machine- and human-readable |
| System/API exchange (roadmap) | **JSON** | Integrations, CAF pipelines |

---

## 3. Import pipeline (shared)

```
Upload
  → detect format + domain template
  → parse (streaming for large files)
  → per-row Zod validation (structural + semantic)
  → resolve references within tenant (e.g. link child → family by key)
  → dry-run diff (create / update / skip / error) — previewed before commit
  → confirm
  → execute in batched transactions (idempotent upsert by natural key)
  → audit + report (downloadable: successes and a per-row error file)
```

- **Dry-run first:** operators see exactly what will happen before committing — counts and a downloadable error report for invalid rows.
- **Idempotent:** re-importing the same file updates rather than duplicates, keyed by declared natural keys per domain.
- **Partial-safe:** valid rows can be committed while invalid rows are returned for correction (configurable: all-or-nothing vs best-effort), always with a precise error report.
- **Large files:** streamed and batched to stay within serverless limits; long imports run as a background job with progress (see [deployment.md](deployment.md) on jobs).

---

## 4. Export pipeline (shared)

```
Request (domain + filters + format)
  → authorize (permission + tenant scope)
  → query via tenant-scoped repositories (soft-deleted excluded unless explicitly requested)
  → map to the export schema (stable columns, localized labels)
  → render (CSV/XLSX/PDF/JSON)
  → audit the export (who exported what, when)
  → deliver (stream / signed Storage URL)
```

- Exports are **tenant-scoped** and **permission-gated**; sensitive columns (PAI/health) require their specific permission and are audited at row level.
- Column sets are **stable, documented schemas** so downstream consumers (and re-imports) don't break.

---

## 5. Domain plug-ins

Each domain that supports import/export provides:
- a **column/field schema** (Zod) and a mapping to/from its domain model;
- **natural keys** for idempotent upsert;
- **reference resolvers** (how to link rows to existing tenant data);
- **example templates** (a downloadable blank CSV/XLSX with headers and notes).

The shared framework (`@stan/*` + an `import-export` module) handles parsing, validation orchestration, dry-run, batching, auditing, and reporting. Domains contribute only their schema and mapping — no duplicated pipeline code.

---

## 6. Safety & compliance

- **Validation everywhere** (Zod) — no unvalidated row reaches a repository.
- **Rate-limited** and size-limited to prevent abuse/DoS (see [security.md](security.md)).
- **Audited** — every import/export is an audit event with counts and actor.
- **GDPR:** the per-subject export (portability) and erasure export are specializations of this framework, permission-gated and audited (see [security.md](security.md)).
- **No cross-tenant leakage** — the tenant-scoped client guarantees exports can only contain the current municipality's data.

---

## 7. Rules for engineers (enforced)

1. Never write a bespoke parser/validator per feature — plug into the shared import/export framework.
2. Every imported row is Zod-validated; invalid rows are reported, never silently handled.
3. Imports/exports are tenant-scoped, permission-gated, and audited.
4. Upsert by declared natural keys; never duplicate on re-import.
5. Provide a downloadable template and a documented, stable column schema for every supported domain.
6. Stream and batch large files; long-running imports use background jobs.
