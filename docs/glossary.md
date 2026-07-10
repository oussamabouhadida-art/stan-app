# Glossary

Shared vocabulary for Stan. Two audiences: the **domain** (French municipal childhood/youth services) and the **system** (our architecture). Code identifiers are English; this glossary bridges the domain terms to them.

---

## Domain terms (French municipal context)

| Term | Meaning |
| --- | --- |
| **Municipality** (commune) | A French local authority. The **tenant** in Stan. |
| **Community of municipalities** (communauté de communes / d'agglomération) | A grouping of municipalities. Used for cross-tenant *reporting*; not the isolation boundary. |
| **Structure** | A physical/organizational unit: school (école), leisure centre (centre de loisirs / ALSH), youth centre, holiday centre. |
| **After-school** (périscolaire) | Activities around school hours (morning care, lunch, evening). |
| **Extracurricular / Holiday** (extrascolaire) | Activities on non-school days and holidays (ALSH, holiday centres). |
| **Session** | A dated occurrence of an activity a child can attend (e.g. a specific afternoon at a leisure centre). |
| **Activity / Program / Workshop** (activité / programme / atelier) | The offer children/youth can enrol in. |
| **Attendance** (présence / pointage) | Record that a child was present at a session. |
| **Family** (famille) | The household/guardians linked to children. |
| **Child** (enfant) | A minor enrolled in services. |
| **Youth** (jeune) | Older minors/young people using youth services. |
| **Passport Jeune** | A municipal youth benefit/program (varies per municipality — always configurable). |
| **CAF** | *Caisse d'Allocations Familiales* — the French family-benefits authority. Municipalities report indicators to it. |
| **PAI** | *Projet d'Accueil Individualisé* — an individualized care plan (often medical/allergy). **Sensitive data.** |
| **Handicap follow-up** | Tracking accommodations for children with disabilities. **Sensitive data.** |
| **Zone A / B / C** | France's three school-holiday zones; determine holiday dates per region. |
| **School year** (année scolaire) | The operational year most data is bound to. |
| **Manager / Director** (responsable / directeur) | Staff who manage structures/services. A user role. |
| **Animator** (animateur) | Field staff running activities and recording attendance. A user role. |
| **Municipal agent** | Any staff user of the platform. |
| **SIRET / INSEE code** | French legal/statistical identifiers for the municipality/structures. |

---

## System terms

| Term | Meaning | Reference |
| --- | --- | --- |
| **Tenant** | A municipality; the unit of data isolation. | [multi-tenancy.md](multi-tenancy.md) |
| **`TenantContext`** | Server-resolved `{ userId, municipalityId, membershipId, roleId, permissions, isSuperAdmin }` passed into services. | [multi-tenancy.md](multi-tenancy.md) |
| **Tenant-scoped client** | The Prisma client extension that injects `municipalityId` and forbids unscoped tenant queries. | [multi-tenancy.md](multi-tenancy.md) |
| **RLS** | Postgres Row-Level Security — the database-level isolation backstop. | [multi-tenancy.md](multi-tenancy.md) |
| **Membership** | A user's role within a specific municipality (a user can have several). | [authorization-rbac.md](authorization-rbac.md) |
| **Permission** | An atomic capability key (`domain.action`) checked in code. | [authorization-rbac.md](authorization-rbac.md) |
| **Role** | A per-municipality, editable bundle of permissions. | [authorization-rbac.md](authorization-rbac.md) |
| **Service / use-case** | Framework-agnostic business operation; where rules and authorization live. | [architecture.md](architecture.md) |
| **Repository** | The only Prisma-calling layer; tenant-scoped, intention-revealing. | [architecture.md](architecture.md) |
| **Transport adapter** | A Server Action or Route Handler; thin glue over a service. | [architecture.md](architecture.md) |
| **Module** | A self-contained feature domain under `apps/web/modules/*`. | [folder-structure.md](folder-structure.md) |
| **Provisioning** | Installing/updating a municipality from one config file. | [municipality-initialization.md](municipality-initialization.md) |
| **Soft delete** | Marking a row `deleted_at` instead of removing it. | [database-philosophy.md](database-philosophy.md) |
| **Audit trail** | Append-only "who did what, when, in which tenant". | [audit.md](audit.md) |
| **ADR** | Architecture Decision Record. | [adr/](adr) |
| **Super-admin** | Platform operator (us); not a tenant role. | [authentication.md](authentication.md) |
| **Config tiers** | Platform config / tenant config / secrets. | [configuration-strategy.md](configuration-strategy.md) |

---

## Naming rule

- **Code identifiers are English** (`Child`, `attendanceRecord`, `openingHours`).
- **User-facing text is localized** (French default) via i18n, never hardcoded in components.
- **Domain nouns** map 1:1 where possible: commune → `Municipality`, enfant → `Child`, présence → `AttendanceRecord`, structure → `Structure`.
