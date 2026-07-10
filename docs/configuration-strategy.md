# Configuration strategy

The core promise of Stan: **the codebase is identical for every customer; only the data changes** (Context.md, *Core Principle*). This document defines how "everything is configurable" is actually achieved, so that no municipality-specific value ever enters the source code.

Related: [municipality-initialization.md](municipality-initialization.md), [import-export.md](import-export.md).

---

## 1. The rule

> If a value could differ between two municipalities, it is **data**, not code.

That includes: municipality identity (name, logo, colours, address, contacts), structures (schools, leisure/youth/holiday centres), opening hours, school calendars and holiday periods, zone A/B/C, public holidays, pricing, CAF settings, programs/workshops/activities, neighborhoods and streets, roles and permissions, email domains, banners/theming, and **which modules are enabled**. (Context.md, *Administration* & *No Hardcoded Data*.)

There are **zero** exceptions. A hardcoded municipality value is a blocking defect.

---

## 2. Three tiers of configuration

Not all "configuration" is the same. We separate three tiers with different owners and change processes:

| Tier | What | Storage | Who changes it | Change process |
| --- | --- | --- | --- | --- |
| **Platform config** | Things true for *all* tenants: feature flags at platform level, default role templates, permission catalog, supported locales | Code + DB seed | Us (engineering) | Deploy / migration |
| **Tenant config** | Everything municipality-specific (the list in §1) | Database, tenant-scoped | Municipality admins | Administration UI, at runtime, no deploy |
| **Runtime secrets** | API keys, DB URL, provider tokens | Encrypted env vars | Us (ops) | [security.md](security.md) |

The heart of the product is **Tier 2**: fully editable at runtime through Administration, no developer involvement.

---

## 3. Tenant configuration lives in the database

- Tenant config is **normalized relational data**, not a blob. Structures are rows in `structures`, opening hours are rows in `opening_hours`, pricing tiers are rows in `pricing`, roles are rows in `roles`, etc. This gives us integrity constraints, history, and queryability.
- A small amount of genuinely free-form or rarely-queried settings (e.g. misc UI preferences) may use a typed **`settings` key/value** table with Zod-validated values — but structured domain config is always modelled as proper tables.
- All of it is tenant-scoped and audited (config changes are always audited — see [audit.md](audit.md)).

---

## 4. Reading configuration in code

- Code **never** contains a municipality value. It asks the **configuration service** for the current tenant's value:
  ```ts
  const hours = await openingHoursService.forStructure(ctx, structureId, onDate);
  const theme = await themeService.forMunicipality(ctx);          // colours, logo
  const isEnabled = await moduleService.isEnabled(ctx, 'passport-jeune');
  ```
- Config reads are **tenant-scoped** and cached per municipality (cache keyed by `municipalityId`, invalidated on config change) so the Administration UI feels instant without hammering the DB.
- **Feature/module gating**: whether a domain (e.g. Passport Jeune, Trips, CAF) is active for a municipality is config. Disabled modules are hidden in the UI and their routes/services refuse access — from data, not `if (municipality === …)`.

---

## 5. Theming & identity (no hardcoded branding)

- Logo, colours, banner, name, contact details come from tenant config and drive `@stan/ui`'s theme provider at runtime. Two municipalities render with different branding from the *same* build.
- No colour hex, no logo path, no municipality name appears in the codebase or in a build-time constant.

---

## 6. Temporal configuration

Configuration changes over time and history must be preserved (see [database-philosophy.md](database-philosophy.md) §8):

- School calendars, holiday periods, opening hours, and pricing are **validity-bound** (per school year or `valid_from`/`valid_to`). Editing next year's pricing never rewrites this year's.
- The config service always resolves **the value effective on a given date**, so statistics and CAF reporting stay historically accurate.

---

## 7. Validation

- Every configuration value is validated with **Zod** on write (Administration form *and* server) and on import (config file). Invalid config cannot be saved.
- Schemas for the config file format live in `@stan/config`; schemas for individual Administration forms live in the `administration` module and reuse `@stan/validation` primitives (FR phone, postal code, SIRET, email).
- Cross-field and cross-entity invariants (e.g. a holiday period must fall within the school year; a pricing tier references an existing program) are enforced at the service layer.

---

## 8. Defaults without hardcoding

- New municipalities can start from an **optional template** shipped as *data* (a default config file / seed), giving sensible French-context defaults (zone A/B/C definitions, standard public holidays, a recommended role set). Admins then edit freely.
- These templates are configuration artifacts, **not** code branches. Choosing to apply one is explicit.

---

## 9. Administration is the surface

Every Tier-2 value is editable through the **Administration** module, which replaces the legacy `/config`, `/acces`, and `/outils_maintenance` (Context.md). Administration is designed and built as a first-class domain (see [roadmap.md](roadmap.md)); it is where configurability becomes real for the customer.

---

## 10. Rules for engineers (enforced)

1. No municipality-specific literal anywhere in code or build config. Ever.
2. Read tenant config via the config service; never inline a value.
3. Model structured config as normalized tables, not blobs.
4. Validate all config on write and on import with Zod.
5. Gate modules/features by config, resolved from data.
6. Config changes are tenant-scoped and audited.
