# Entity-Relationship Diagrams

Diagrams render on GitHub (Mermaid). Attributes are trimmed to the essential/keys for readability — full columns are in [entities.md](entities.md). Every tenant-scoped table also carries the base columns from [database-philosophy.md](../database-philosophy.md) (`municipality_id`, timestamps, audit-actor, soft-delete) even where not drawn.

Legend: `||--o{` = one-to-many · `}o--o{` = many-to-many (via join) · `||--||` = one-to-one.

---

## 1. Context (how the layers relate)

```mermaid
flowchart TB
    COMM[Community] --> MUN[Municipality  = TENANT]
    MUN --> FOUND[Foundation: Users · Memberships · Roles · Permissions · Audit · Settings · Modules]
    MUN --> CONF[Configuration: Structures · Calendars · Opening hours · Programs · Pricing · CAF · Neighborhoods]
    MUN --> PEOPLE[People: Families · Guardians · Children/Youth · Guardianships · Enrolments]
    MUN --> OPS[Operations: Sessions · Attendance · Meals · Trips · Passport · PAI · Handicap · Documents · Notifications · Emails]
    CONF --> PEOPLE
    CONF --> OPS
    PEOPLE --> OPS
```

Everything below `Municipality` is tenant-scoped. `Community`, `User`, and the `Permission` catalog are **global** (not owned by a single tenant).

---

## 2. Foundation — tenancy, identity, access, audit

```mermaid
erDiagram
    COMMUNITY   ||--o{ MUNICIPALITY : groups
    MUNICIPALITY ||--o{ MEMBERSHIP  : has
    MUNICIPALITY ||--o{ ROLE        : defines
    MUNICIPALITY ||--o{ SETTING     : configures
    MUNICIPALITY ||--o{ MUNICIPALITY_MODULE : enables
    MUNICIPALITY ||--o{ EMAIL_DOMAIN : allows
    MUNICIPALITY ||--o{ AUDIT_LOG   : records

    USER        ||--o{ MEMBERSHIP  : holds
    ROLE        ||--o{ MEMBERSHIP  : assigned_in
    ROLE        ||--o{ ROLE_PERMISSION : grants
    PERMISSION  ||--o{ ROLE_PERMISSION : granted_by
    MEMBERSHIP  ||--o{ MEMBERSHIP_STRUCTURE : scoped_to

    COMMUNITY {
        uuid id PK
        string name
        string code UK
    }
    MUNICIPALITY {
        uuid id PK
        string code UK
        string name
        uuid community_id FK
        string status
    }
    USER {
        uuid id PK "= Supabase auth uid"
        string email UK
        boolean is_super_admin
        string status
    }
    MEMBERSHIP {
        uuid id PK
        uuid user_id FK
        uuid municipality_id FK
        uuid role_id FK
        string status
    }
    ROLE {
        uuid id PK
        uuid municipality_id FK
        string name
    }
    PERMISSION {
        uuid id PK
        string key UK "domain.action"
        string domain
    }
    ROLE_PERMISSION {
        uuid role_id FK
        uuid permission_id FK
    }
    AUDIT_LOG {
        uuid id PK
        uuid municipality_id FK "nullable = platform"
        uuid actor_user_id FK
        string action
        string entity_type
        uuid entity_id
        jsonb metadata
    }
```

---

## 3. Configuration / structural

```mermaid
erDiagram
    MUNICIPALITY ||--o{ STRUCTURE     : has
    MUNICIPALITY ||--o{ NEIGHBORHOOD  : has
    MUNICIPALITY ||--o{ SCHOOL_YEAR   : defines
    MUNICIPALITY ||--o{ PROGRAM       : offers
    STRUCTURE    ||--o{ OPENING_HOUR  : opens
    STRUCTURE    ||--o{ PROGRAM       : hosts
    NEIGHBORHOOD ||--o{ STRUCTURE     : locates
    SCHOOL_YEAR  ||--o{ HOLIDAY_PERIOD: contains
    SCHOOL_YEAR  ||--o{ PUBLIC_HOLIDAY: contains
    PROGRAM      ||--o{ PRICING_TIER  : priced_by
    MUNICIPALITY ||--o{ CAF_INDICATOR : tracks

    STRUCTURE {
        uuid id PK
        string code UK
        string name
        string type "SCHOOL|LEISURE|YOUTH|HOLIDAY"
        int capacity
        decimal geo_lat
        decimal geo_lng
    }
    SCHOOL_YEAR {
        uuid id PK
        string label UK "2025-2026"
        date starts_on
        date ends_on
        string zone "A|B|C"
    }
    HOLIDAY_PERIOD {
        uuid id PK
        uuid school_year_id FK
        date starts_on
        date ends_on
    }
    OPENING_HOUR {
        uuid id PK
        uuid structure_id FK
        string day_of_week
        time opens_at
        time closes_at
        date valid_from
        date valid_to
    }
    PROGRAM {
        uuid id PK
        string code UK
        string type "ACTIVITY|WORKSHOP"
        int min_age
        int max_age
    }
    PRICING_TIER {
        uuid id PK
        uuid program_id FK
        int amount_cents
        int quotient_min
        int quotient_max
    }
```

---

## 4. People

```mermaid
erDiagram
    MUNICIPALITY ||--o{ FAMILY   : has
    FAMILY       ||--o{ GUARDIAN : includes
    FAMILY       ||--o{ CHILD    : includes
    CHILD        ||--o{ GUARDIANSHIP : linked_by
    GUARDIAN     ||--o{ GUARDIANSHIP : linked_by
    CHILD        ||--o{ ENROLLMENT   : registers
    PROGRAM      ||--o{ ENROLLMENT   : receives
    SCHOOL_YEAR  ||--o{ ENROLLMENT   : within
    NEIGHBORHOOD ||--o{ FAMILY       : locates
    STRUCTURE    ||--o{ CHILD        : schooled_at

    FAMILY {
        uuid id PK
        string name
        string caf_number
        int caf_quotient
        uuid neighborhood_id FK
    }
    GUARDIAN {
        uuid id PK
        uuid family_id FK
        string first_name
        string last_name
        string email
        string phone
    }
    CHILD {
        uuid id PK
        uuid family_id FK
        string first_name
        string last_name
        date birth_date
        uuid school_structure_id FK
    }
    GUARDIANSHIP {
        uuid child_id FK
        uuid guardian_id FK
        string relationship "MOTHER|FATHER|LEGAL_GUARDIAN|OTHER"
        boolean is_primary
    }
    ENROLLMENT {
        uuid id PK
        uuid child_id FK
        uuid program_id FK
        uuid school_year_id FK
        string status
    }
```

---

## 5. Operations (first-pass — refined per-domain in Phase 4)

```mermaid
erDiagram
    PROGRAM   ||--o{ SESSION            : occurs_as
    STRUCTURE ||--o{ SESSION            : hosts
    SESSION   ||--o{ ATTENDANCE_RECORD  : tracks
    CHILD     ||--o{ ATTENDANCE_RECORD  : attends
    SESSION   ||--o{ MEAL               : serves
    CHILD     ||--o{ MEAL               : consumes
    TRIP      ||--o{ TRIP_PARTICIPATION : carries
    CHILD     ||--o{ TRIP_PARTICIPATION : joins
    CHILD     ||--o{ PASSPORT_JEUNE     : holds
    CHILD     ||--o{ PAI                : has
    CHILD     ||--o{ HANDICAP_FOLLOWUP  : has
    CHILD     ||--o{ DOCUMENT           : owns
    FAMILY    ||--o{ DOCUMENT           : owns
    USER      ||--o{ NOTIFICATION       : receives
    MUNICIPALITY ||--o{ EMAIL_TEMPLATE  : defines
    MUNICIPALITY ||--o{ EMAIL_LOG       : sends

    SESSION {
        uuid id PK
        uuid program_id FK
        uuid structure_id FK
        date date
        time starts_at
        time ends_at
        int capacity
    }
    ATTENDANCE_RECORD {
        uuid id PK
        uuid session_id FK
        uuid child_id FK
        string status "PRESENT|ABSENT|EXCUSED|LATE"
        timestamp checked_in_at
    }
    PAI {
        uuid id PK
        uuid child_id FK
        string type "SENSITIVE"
        date starts_on
        date ends_on
    }
    DOCUMENT {
        uuid id PK
        string owner_type
        uuid owner_id
        string storage_path
        string mime_type
    }
```

> `PAI` and `HANDICAP_FOLLOWUP` hold **Art. 9 sensitive data** — dedicated permissions + row-level audit (see [security.md](../security.md), [authorization-rbac.md](../authorization-rbac.md)).

Full column-by-column detail, indexes, and constraints for all entities: [entities.md](entities.md).
