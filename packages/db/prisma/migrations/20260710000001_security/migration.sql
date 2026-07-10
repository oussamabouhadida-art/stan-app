-- Stan — security & integrity migration.
-- Adds what the Prisma schema can't express: scalar-column foreign keys, partial
-- unique indexes (soft-delete aware), CHECK constraints, and Row-Level Security.
-- Applied with `prisma migrate deploy`. See docs/multi-tenancy.md and docs/database/.

-- ── Foreign keys for scalar `municipality_id` on every tenant table ──────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT table_name FROM information_schema.columns
    WHERE table_schema = 'public' AND column_name = 'municipality_id'
    ORDER BY table_name
  LOOP
    EXECUTE format(
      'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (municipality_id) REFERENCES municipalities(id) ON DELETE RESTRICT',
      r.table_name, r.table_name || '_municipality_id_fkey'
    );
  END LOOP;
END $$;

-- ── Foreign keys for scalar user / membership references ─────────────────────
ALTER TABLE "documents"
  ADD CONSTRAINT "documents_uploaded_by_fkey"
  FOREIGN KEY ("uploaded_by") REFERENCES "users"("id") ON DELETE SET NULL;
ALTER TABLE "notifications"
  ADD CONSTRAINT "notifications_recipient_user_id_fkey"
  FOREIGN KEY ("recipient_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
ALTER TABLE "audit_logs"
  ADD CONSTRAINT "audit_logs_actor_user_id_fkey"
  FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE SET NULL;
ALTER TABLE "audit_logs"
  ADD CONSTRAINT "audit_logs_actor_membership_id_fkey"
  FOREIGN KEY ("actor_membership_id") REFERENCES "memberships"("id") ON DELETE SET NULL;

-- ── Partial unique indexes (uniqueness among live, non-deleted rows) ─────────
CREATE UNIQUE INDEX "memberships_user_municipality_key"
  ON "memberships" ("user_id", "municipality_id") WHERE "deleted_at" IS NULL;
CREATE UNIQUE INDEX "roles_municipality_name_key"
  ON "roles" ("municipality_id", "name") WHERE "deleted_at" IS NULL;
CREATE UNIQUE INDEX "neighborhoods_municipality_name_key"
  ON "neighborhoods" ("municipality_id", "name") WHERE "deleted_at" IS NULL;
CREATE UNIQUE INDEX "structures_municipality_code_key"
  ON "structures" ("municipality_id", "code") WHERE "deleted_at" IS NULL;
CREATE UNIQUE INDEX "programs_municipality_code_key"
  ON "programs" ("municipality_id", "code") WHERE "deleted_at" IS NULL;
CREATE UNIQUE INDEX "families_municipality_reference_key"
  ON "families" ("municipality_id", "reference")
  WHERE "reference" IS NOT NULL AND "deleted_at" IS NULL;
CREATE UNIQUE INDEX "enrollments_child_program_year_period_key"
  ON "enrollments" ("child_id", "program_id", "school_year_id", (COALESCE("period", '')))
  WHERE "deleted_at" IS NULL;
CREATE UNIQUE INDEX "attendance_records_session_child_key"
  ON "attendance_records" ("session_id", "child_id") WHERE "deleted_at" IS NULL;

-- ── CHECK constraints (invariants the database guarantees) ───────────────────
ALTER TABLE "structures"
  ADD CONSTRAINT "structures_capacity_check" CHECK ("capacity" IS NULL OR "capacity" >= 0);
ALTER TABLE "school_years"
  ADD CONSTRAINT "school_years_dates_check" CHECK ("ends_on" > "starts_on");
ALTER TABLE "holiday_periods"
  ADD CONSTRAINT "holiday_periods_dates_check" CHECK ("ends_on" >= "starts_on");
ALTER TABLE "opening_hours"
  ADD CONSTRAINT "opening_hours_time_check" CHECK ("closes_at" > "opens_at");
ALTER TABLE "programs"
  ADD CONSTRAINT "programs_age_check"
  CHECK ("min_age" IS NULL OR "max_age" IS NULL OR "max_age" >= "min_age");
ALTER TABLE "pricing_tiers"
  ADD CONSTRAINT "pricing_tiers_amount_check" CHECK ("amount_cents" >= 0);
ALTER TABLE "pricing_tiers"
  ADD CONSTRAINT "pricing_tiers_quotient_check"
  CHECK ("quotient_min" IS NULL OR "quotient_max" IS NULL OR "quotient_max" >= "quotient_min");
ALTER TABLE "sessions"
  ADD CONSTRAINT "sessions_time_check" CHECK ("ends_at" > "starts_at");
ALTER TABLE "documents"
  ADD CONSTRAINT "documents_owner_type_check"
  CHECK ("owner_type" IN ('child', 'family', 'guardian', 'structure'));
ALTER TABLE "documents"
  ADD CONSTRAINT "documents_size_check" CHECK ("size_bytes" >= 0);

-- ── Row-Level Security (Wall 2) on every tenant table ────────────────────────
-- Deny-by-default: rows are visible only when app.current_municipality matches.
-- Set per transaction via withTenantRls(). Takes effect when the app connects with a
-- role WITHOUT BYPASSRLS (provisioned with the auth layer in Phase 3); superuser
-- connections (migrations, seed) bypass it by design.
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT table_name FROM information_schema.columns
    WHERE table_schema = 'public' AND column_name = 'municipality_id'
    ORDER BY table_name
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', r.table_name);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', r.table_name);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON %I '
      'USING (municipality_id = NULLIF(current_setting(''app.current_municipality'', true), '''')::uuid) '
      'WITH CHECK (municipality_id = NULLIF(current_setting(''app.current_municipality'', true), '''')::uuid)',
      r.table_name
    );
  END LOOP;
END $$;
