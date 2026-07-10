# Municipality configuration file — schema reference

This document describes the **structure** of the single file that installs or updates a municipality (Context.md, *Municipality Configuration*). It is documentation of the format; the authoritative, executable schema is the Zod schema in `@stan/config` (built in Phase 2). An annotated example lives at [municipality.example.yaml](municipality.example.yaml).

- **Formats:** YAML or JSON (equivalent; YAML shown for readability).
- **Validation:** the file is fully Zod-validated before anything is written (structural + semantic invariants). See [municipality-initialization.md](../municipality-initialization.md).
- **Idempotent:** re-importing upserts by the **natural keys** noted below; it never duplicates and never auto-deletes.
- **No secrets:** users are referenced by email + role; identities are created in Supabase with an invitation. **Never put passwords in this file.**

---

## Top-level shape

```yaml
version: 1                 # config format version (required)
municipality: { ... }      # identity (required)
modules: { ... }           # enabled business domains (required)
structures: [ ... ]        # schools / centres (required, >= 1)
schoolYears: [ ... ]       # calendars, holidays, zones
openingHours: [ ... ]      # per structure / period
programs: [ ... ]          # activities / workshops
pricing: [ ... ]           # tiers and rules
caf: { ... }               # CAF indicators/settings
roles: [ ... ]             # role -> permissions (seed, editable after)
users: [ ... ]             # managers / animators (email + role)
emailDomains: [ ... ]      # allowed email domains
settings: { ... }          # remaining tenant preferences
```

Every section is validated; unknown keys are rejected (fail-fast) so typos surface immediately.

---

## Sections

### `municipality` (identity) — natural key: `code`
| Field | Type | Req | Notes |
| --- | --- | --- | --- |
| `code` | string | ✓ | Stable unique key (e.g. INSEE code). Used for idempotent upsert. |
| `name` | string | ✓ | Display name. |
| `siret` | string | – | Validated (SIRET). |
| `timezone` | string | ✓ | Default `Europe/Paris`. |
| `locale` | string | ✓ | Default `fr-FR`. |
| `address` | object | ✓ | `street`, `postalCode` (FR), `city`. |
| `contact` | object | ✓ | `email`, `phone` (FR). |
| `branding` | object | – | `logoUrl`, `primaryColor`, `secondaryColor`, `banner`. Drives runtime theme. |

### `modules` (feature gating)
Booleans enabling business domains for this tenant, e.g.:
```yaml
modules:
  families: true
  attendance: true
  meals: true
  trips: true
  passportJeune: false
  caf: true
  gis: true
```
Disabled modules are hidden and their services refuse access (from data, not code).

### `structures[]` — natural key: `code`
`code` (unique per municipality), `name`, `type` (`school | leisure | youth | holiday`), `address`, `capacity` (≥ 0), optional `geo` (`lat`, `lng` for GIS).

### `schoolYears[]` — natural key: `label`
`label` (e.g. `2025-2026`), `startsOn`, `endsOn`, `zone` (`A | B | C`), `holidayPeriods[]` (`name`, `startsOn`, `endsOn`, must fall within the year), `publicHolidays[]` (`name`, `date`).

### `openingHours[]`
Bound to a `structureCode` and a validity range or school year; day-of-week windows (`day`, `opensAt`, `closesAt`, optional `period`). Validated so `closesAt > opensAt`.

### `programs[]` — natural key: `code`
`code`, `name`, `type` (`activity | workshop`), optional `structureCode`, age bracket (`minAge`, `maxAge`), optional capacity.

### `pricing[]`
Tiers referencing a `programCode` (or global), with `label`, `amount` (EUR, minor units or decimal), and rule fields (e.g. quotient-based). Validated to reference existing programs.

### `caf`
Municipality-specific CAF indicators/rules to track and report. Structure is configurable; validated against the CAF settings schema.

### `roles[]` — natural key: `name`
`name`, optional `description`, `permissions[]` (keys from the global permission catalog). Seeds editable roles; **not** code. Invalid permission keys are rejected.

### `users[]` — natural key: `email`
`email`, `firstName`, `lastName`, `roleName` (must match a `roles[]` entry), optional `structureCodes[]` (assignment scope). No passwords — an invitation is sent.

### `emailDomains[]`
Allowed domains (e.g. `ville-example.fr`), validated.

### `settings`
Typed key/value for remaining preferences (Zod-validated values), for anything not worth a dedicated table.

---

## Validation rules (semantic, beyond field types)

- `municipality.code` unique; used as the upsert key.
- Structure/program/role names and codes unique **within** the municipality.
- Holiday periods ⊆ their school year; `endsOn ≥ startsOn` everywhere.
- Opening hours: `closesAt > opensAt`; `structureCode` must exist.
- Pricing `programCode` must exist; amounts ≥ 0.
- `users[].roleName` must exist in `roles[]`; `structureCodes` must exist.
- Permission keys must exist in the global catalog.
- All strings trimmed; FR-specific formats (phone, postal code, SIRET) validated.

A failure produces a precise, field-referenced error report and **zero** database writes.

---

## Lifecycle

1. **Install:** first import creates the tenant and all entities atomically.
2. **Update:** re-import upserts changed rows (by natural key), reports a diff; **never** auto-deletes.
3. **Templates:** a shipped default file provides FR-context starting points (zones, public holidays, a recommended role set) — all editable afterwards.

See the runnable example: [municipality.example.yaml](municipality.example.yaml).
