# PROJECT CONTEXT

Version: 1.0

---

# Vision

This project is NOT a migration of an existing PHP website.

The objective is to create a modern SaaS platform dedicated to French municipalities and local authorities to manage Childhood, Youth, After-school activities and Holiday programs.

The existing PHP application only serves as a functional reference and proof of concept.

The new application must be designed as a commercial software product that can be deployed to hundreds of municipalities.

---

# Product Vision

Create the reference SaaS platform for municipalities between 2,000 and 100,000 inhabitants.

The platform must simplify the daily work of municipal services while providing reliable operational and strategic data.

The software must replace paper processes, Excel files, duplicated data and manual reporting.

Every municipality should be able to configure the application without any software development.

---

# Background

The original application was developed for the City of Créteil.

It already manages many operational processes including:

- Youth
- Childhood
- After-school
- Holiday programs
- Attendance
- Meals
- Trips
- Passport Jeune
- CAF indicators
- Documents
- PAI
- Dashboards
- Statistics

Although operational, the original application contains many municipality-specific configurations.

Examples:

- municipality name
- structures
- managers
- animators
- opening hours
- school holidays
- CAF rules
- email domains
- banners
- parameters

Those configurations must disappear from the source code.

Everything must become configurable.

---

# Philosophy

Never think "Créteil".

Always think "Any municipality".

Créteil becomes only one possible configuration among many.

The software must never assume any municipality-specific value.

Everything must be data-driven.

---

# Target Users

Municipalities

Communities of municipalities

Youth services

Childhood services

After-school services

Holiday centres

Leisure centres

Schools

---

# Core Principle

The codebase must remain identical for every customer.

Only the data changes.

Everything must be configurable from the Administration interface.

No municipality-specific code.

No duplicated projects.

One SaaS.

One codebase.

Unlimited municipalities.

---

# Multi Tenant Architecture

The platform is multi-tenant.

Every municipality owns its own data.

Data isolation is mandatory.

Example:

Municipality

├── Structures

├── Users

├── Families

├── Children

├── Youth

├── Activities

├── Attendance

├── Meals

├── Trips

├── Statistics

└── Configuration

No municipality can access another municipality's data.

---

# Main Business Domains

Authentication

Users

Families

Children

Youth

Attendance

Meals

Trips

Activities

Holiday sessions

After-school sessions

Passport Jeune

CAF statistics

PAI

Handicap follow-up

Documents

Notifications

Emails

Reporting

GIS

Administration

Audit logs

---

# Product Principles

Everything configurable

Everything reusable

Everything modular

Everything scalable

Everything responsive

Everything accessible

Everything documented

---

# Administration

The administration panel is the heart of the application.

It replaces every manual configuration currently located inside:

/config

/acces

/outils_maintenance

Every parameter must become editable through the UI.

Examples:

Municipality identity

Logo

Colors

Address

Phone

Email

Structures

Schools

Leisure centres

Youth centres

Holiday centres

Opening hours

School calendar

Holiday periods

Zone A/B/C

Public holidays

Pricing

CAF settings

Programs

Workshops

Activities

Neighborhoods

Streets

Permissions

Roles

Email domains

Animated banner

Enabled modules

Everything must be editable.

---

# Municipality Configuration

A municipality must be installable from one configuration file.

Supported formats:

YAML

JSON

Example:

municipality.yaml

This file describes:

Municipality identity

Structures

Opening hours

Managers

Animators

Programs

Pricing

CAF settings

Permissions

Email domains

School calendar

Modules

Importing this file should completely initialize a municipality.

---

# No Hardcoded Data

Never hardcode:

Municipality names

Structure names

Programs

Schedules

Email domains

Roles

School zones

CAF values

Everything comes from the database.

---

# Database Philosophy

The database must be redesigned.

Do NOT reproduce the old SQL schema.

Normalize the model.

Use Prisma.

Every table should include:

id

createdAt

updatedAt

when relevant:

municipalityId

createdBy

updatedBy

deletedAt (soft delete)

Audit history should be preserved.

---

# Technical Stack

Frontend

Next.js

React

TypeScript

TailwindCSS

shadcn/ui

TanStack Table

React Hook Form

React Query

Framer Motion

Backend

Next.js Server Actions

Route Handlers

Prisma ORM

Database

Supabase PostgreSQL

Authentication

Supabase Auth

Storage

Supabase Storage

Deployment

GitHub

Vercel

---

# User Experience

Tablet-first

Fast

Modern

Beautiful

Minimal clicks

Accessible

Responsive

Optimized for municipal agents working on the field.

---

# Security

RBAC

Audit logs

Soft delete

GDPR

Encrypted secrets

Rate limiting

CSRF protection

Secure authentication

---

# Code Quality

Strict TypeScript

Clean Architecture

SOLID

Feature-based architecture

Reusable components

Reusable hooks

Repository pattern

Service layer

Validation everywhere

No duplicated code

Production-ready only

---

# Future AI Features

Automatic report generation

Attendance anomaly detection

CAF assistance

Planning assistant

Automatic email writing

Predictive dashboards

Natural language search

Document summarization

---

# Development Rules

Never generate large amounts of code blindly.

Proceed incrementally.

For every feature:

1. Explain architecture decisions.

2. Design database.

3. Create Prisma schema.

4. Create migrations.

5. Generate backend.

6. Generate frontend.

7. Generate tests.

8. Run lint.

9. Run type checking.

10. Commit.

11. Push to GitHub.

12. Deploy to Vercel.

13. Verify deployment.

Never leave TODOs.

Never leave dead code.

Never leave commented code.

---

# Role of Claude Code

Act as:

CTO

Lead Software Architect

Senior Product Manager

Senior UX Designer

Senior Full Stack Engineer

Challenge architectural decisions.

Suggest improvements.

Prefer maintainability over speed.

The objective is to build a software company, not a one-off project.

Every decision must support long-term scalability.
