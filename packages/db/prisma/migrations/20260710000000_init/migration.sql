-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "municipality_status" AS ENUM ('ACTIVE', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "user_status" AS ENUM ('ACTIVE', 'DISABLED');

-- CreateEnum
CREATE TYPE "membership_status" AS ENUM ('INVITED', 'ACTIVE', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "audit_severity" AS ENUM ('INFO', 'NOTICE', 'SECURITY');

-- CreateEnum
CREATE TYPE "structure_type" AS ENUM ('SCHOOL', 'LEISURE', 'YOUTH', 'HOLIDAY');

-- CreateEnum
CREATE TYPE "holiday_zone" AS ENUM ('A', 'B', 'C');

-- CreateEnum
CREATE TYPE "weekday" AS ENUM ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY');

-- CreateEnum
CREATE TYPE "program_type" AS ENUM ('ACTIVITY', 'WORKSHOP');

-- CreateEnum
CREATE TYPE "pricing_rule_type" AS ENUM ('FLAT', 'QUOTIENT');

-- CreateEnum
CREATE TYPE "sex" AS ENUM ('MALE', 'FEMALE', 'UNSPECIFIED');

-- CreateEnum
CREATE TYPE "guardian_relationship" AS ENUM ('MOTHER', 'FATHER', 'LEGAL_GUARDIAN', 'OTHER');

-- CreateEnum
CREATE TYPE "enrollment_status" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "attendance_status" AS ENUM ('PRESENT', 'ABSENT', 'EXCUSED', 'LATE');

-- CreateEnum
CREATE TYPE "participation_status" AS ENUM ('REGISTERED', 'CANCELLED', 'ATTENDED');

-- CreateEnum
CREATE TYPE "email_status" AS ENUM ('QUEUED', 'SENT', 'FAILED');

-- CreateTable
CREATE TABLE "communities" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "communities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "municipalities" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "community_id" UUID,
    "siret" TEXT,
    "timezone" TEXT NOT NULL DEFAULT 'Europe/Paris',
    "locale" TEXT NOT NULL DEFAULT 'fr-FR',
    "address_street" TEXT,
    "address_postal_code" TEXT,
    "address_city" TEXT,
    "contact_email" TEXT,
    "contact_phone" TEXT,
    "logo_url" TEXT,
    "primary_color" TEXT,
    "secondary_color" TEXT,
    "banner" TEXT,
    "status" "municipality_status" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "municipalities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "locale" TEXT NOT NULL DEFAULT 'fr-FR',
    "is_super_admin" BOOLEAN NOT NULL DEFAULT false,
    "status" "user_status" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "memberships" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "status" "membership_status" NOT NULL DEFAULT 'INVITED',
    "invited_at" TIMESTAMPTZ(6),
    "accepted_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "is_template" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "permissions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "key" TEXT NOT NULL,
    "domain" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "role_permissions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "permission_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "membership_structures" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "membership_id" UUID NOT NULL,
    "structure_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "membership_structures_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID,
    "actor_user_id" UUID,
    "actor_membership_id" UUID,
    "action" TEXT NOT NULL,
    "entity_type" TEXT NOT NULL,
    "entity_id" UUID,
    "summary" TEXT NOT NULL,
    "metadata" JSONB,
    "severity" "audit_severity" NOT NULL DEFAULT 'INFO',
    "ip" TEXT,
    "user_agent" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "settings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "municipality_modules" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "module_key" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "municipality_modules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "email_domains" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "domain" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "email_domains_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "neighborhoods" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "neighborhoods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "structures" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "structure_type" NOT NULL,
    "neighborhood_id" UUID,
    "address_street" TEXT,
    "address_postal_code" TEXT,
    "address_city" TEXT,
    "geo_lat" DECIMAL(9,6),
    "geo_lng" DECIMAL(9,6),
    "capacity" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "structures_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "school_years" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "label" TEXT NOT NULL,
    "starts_on" DATE NOT NULL,
    "ends_on" DATE NOT NULL,
    "zone" "holiday_zone" NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "school_years_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "holiday_periods" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "school_year_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "starts_on" DATE NOT NULL,
    "ends_on" DATE NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "holiday_periods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public_holidays" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "school_year_id" UUID,
    "name" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "public_holidays_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "opening_hours" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "structure_id" UUID NOT NULL,
    "period" TEXT,
    "day_of_week" "weekday" NOT NULL,
    "opens_at" TIME(6) NOT NULL,
    "closes_at" TIME(6) NOT NULL,
    "valid_from" DATE,
    "valid_to" DATE,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "opening_hours_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "programs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "program_type" NOT NULL,
    "structure_id" UUID,
    "min_age" INTEGER,
    "max_age" INTEGER,
    "capacity" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "programs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pricing_tiers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "program_id" UUID,
    "label" TEXT NOT NULL,
    "amount_cents" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'EUR',
    "rule_type" "pricing_rule_type" NOT NULL,
    "quotient_min" INTEGER,
    "quotient_max" INTEGER,
    "valid_from" DATE,
    "valid_to" DATE,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "pricing_tiers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "caf_indicators" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "caf_indicators_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "families" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "reference" TEXT,
    "name" TEXT NOT NULL,
    "address_street" TEXT,
    "address_postal_code" TEXT,
    "address_city" TEXT,
    "neighborhood_id" UUID,
    "caf_number" TEXT,
    "caf_quotient" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "families_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guardians" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "family_id" UUID NOT NULL,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "guardians_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "children" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "family_id" UUID,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "birth_date" DATE NOT NULL,
    "sex" "sex",
    "school_structure_id" UUID,
    "neighborhood_id" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "children_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guardianships" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "guardian_id" UUID NOT NULL,
    "relationship" "guardian_relationship" NOT NULL,
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guardianships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "enrollments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "program_id" UUID NOT NULL,
    "school_year_id" UUID NOT NULL,
    "period" TEXT,
    "status" "enrollment_status" NOT NULL DEFAULT 'PENDING',
    "starts_on" DATE,
    "ends_on" DATE,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "enrollments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "program_id" UUID NOT NULL,
    "structure_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "starts_at" TIME(6) NOT NULL,
    "ends_at" TIME(6) NOT NULL,
    "capacity" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "attendance_records" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "status" "attendance_status" NOT NULL,
    "checked_in_at" TIMESTAMPTZ(6),
    "checked_out_at" TIMESTAMPTZ(6),
    "notes" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "attendance_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "meals" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "session_id" UUID,
    "child_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "type" TEXT NOT NULL,
    "consumed" BOOLEAN NOT NULL DEFAULT false,
    "dietary_flags" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "meals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trips" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "structure_id" UUID,
    "destination" TEXT,
    "capacity" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "trips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trip_participations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "trip_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "status" "participation_status" NOT NULL DEFAULT 'REGISTERED',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "trip_participations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "passport_jeunes" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "number" TEXT NOT NULL,
    "issued_on" DATE,
    "valid_until" DATE,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "passport_jeunes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pais" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "starts_on" DATE,
    "ends_on" DATE,
    "details" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "pais_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "handicap_followups" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "child_id" UUID NOT NULL,
    "details" JSONB,
    "accommodations" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "handicap_followups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "owner_type" TEXT NOT NULL,
    "owner_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "storage_path" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "size_bytes" INTEGER NOT NULL,
    "uploaded_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "recipient_user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "payload" JSONB,
    "read_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "email_templates" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "key" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "email_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "email_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "municipality_id" UUID NOT NULL,
    "template_key" TEXT,
    "to_address" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "status" "email_status" NOT NULL DEFAULT 'QUEUED',
    "sent_at" TIMESTAMPTZ(6),
    "error" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "email_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "communities_code_key" ON "communities"("code");

-- CreateIndex
CREATE UNIQUE INDEX "municipalities_code_key" ON "municipalities"("code");

-- CreateIndex
CREATE INDEX "municipalities_community_id_idx" ON "municipalities"("community_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "memberships_municipality_id_idx" ON "memberships"("municipality_id");

-- CreateIndex
CREATE INDEX "memberships_user_id_idx" ON "memberships"("user_id");

-- CreateIndex
CREATE INDEX "memberships_role_id_idx" ON "memberships"("role_id");

-- CreateIndex
CREATE INDEX "roles_municipality_id_idx" ON "roles"("municipality_id");

-- CreateIndex
CREATE UNIQUE INDEX "permissions_key_key" ON "permissions"("key");

-- CreateIndex
CREATE INDEX "permissions_domain_idx" ON "permissions"("domain");

-- CreateIndex
CREATE INDEX "role_permissions_permission_id_idx" ON "role_permissions"("permission_id");

-- CreateIndex
CREATE UNIQUE INDEX "role_permissions_role_id_permission_id_key" ON "role_permissions"("role_id", "permission_id");

-- CreateIndex
CREATE INDEX "membership_structures_structure_id_idx" ON "membership_structures"("structure_id");

-- CreateIndex
CREATE UNIQUE INDEX "membership_structures_membership_id_structure_id_key" ON "membership_structures"("membership_id", "structure_id");

-- CreateIndex
CREATE INDEX "audit_logs_municipality_id_created_at_idx" ON "audit_logs"("municipality_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_idx" ON "audit_logs"("entity_type", "entity_id");

-- CreateIndex
CREATE INDEX "audit_logs_actor_user_id_idx" ON "audit_logs"("actor_user_id");

-- CreateIndex
CREATE UNIQUE INDEX "settings_municipality_id_key_key" ON "settings"("municipality_id", "key");

-- CreateIndex
CREATE UNIQUE INDEX "municipality_modules_municipality_id_module_key_key" ON "municipality_modules"("municipality_id", "module_key");

-- CreateIndex
CREATE UNIQUE INDEX "email_domains_municipality_id_domain_key" ON "email_domains"("municipality_id", "domain");

-- CreateIndex
CREATE INDEX "neighborhoods_municipality_id_idx" ON "neighborhoods"("municipality_id");

-- CreateIndex
CREATE INDEX "structures_municipality_id_idx" ON "structures"("municipality_id");

-- CreateIndex
CREATE INDEX "structures_neighborhood_id_idx" ON "structures"("neighborhood_id");

-- CreateIndex
CREATE INDEX "structures_type_idx" ON "structures"("type");

-- CreateIndex
CREATE UNIQUE INDEX "school_years_municipality_id_label_key" ON "school_years"("municipality_id", "label");

-- CreateIndex
CREATE INDEX "holiday_periods_school_year_id_idx" ON "holiday_periods"("school_year_id");

-- CreateIndex
CREATE UNIQUE INDEX "public_holidays_municipality_id_date_name_key" ON "public_holidays"("municipality_id", "date", "name");

-- CreateIndex
CREATE INDEX "opening_hours_structure_id_day_of_week_idx" ON "opening_hours"("structure_id", "day_of_week");

-- CreateIndex
CREATE INDEX "programs_municipality_id_idx" ON "programs"("municipality_id");

-- CreateIndex
CREATE INDEX "programs_structure_id_idx" ON "programs"("structure_id");

-- CreateIndex
CREATE INDEX "programs_type_idx" ON "programs"("type");

-- CreateIndex
CREATE INDEX "pricing_tiers_program_id_idx" ON "pricing_tiers"("program_id");

-- CreateIndex
CREATE UNIQUE INDEX "caf_indicators_municipality_id_key_key" ON "caf_indicators"("municipality_id", "key");

-- CreateIndex
CREATE INDEX "families_municipality_id_idx" ON "families"("municipality_id");

-- CreateIndex
CREATE INDEX "families_neighborhood_id_idx" ON "families"("neighborhood_id");

-- CreateIndex
CREATE INDEX "guardians_municipality_id_idx" ON "guardians"("municipality_id");

-- CreateIndex
CREATE INDEX "guardians_family_id_idx" ON "guardians"("family_id");

-- CreateIndex
CREATE INDEX "children_municipality_id_idx" ON "children"("municipality_id");

-- CreateIndex
CREATE INDEX "children_family_id_idx" ON "children"("family_id");

-- CreateIndex
CREATE INDEX "children_school_structure_id_idx" ON "children"("school_structure_id");

-- CreateIndex
CREATE INDEX "children_birth_date_idx" ON "children"("birth_date");

-- CreateIndex
CREATE INDEX "guardianships_guardian_id_idx" ON "guardianships"("guardian_id");

-- CreateIndex
CREATE UNIQUE INDEX "guardianships_child_id_guardian_id_key" ON "guardianships"("child_id", "guardian_id");

-- CreateIndex
CREATE INDEX "enrollments_municipality_id_idx" ON "enrollments"("municipality_id");

-- CreateIndex
CREATE INDEX "enrollments_program_id_idx" ON "enrollments"("program_id");

-- CreateIndex
CREATE INDEX "enrollments_school_year_id_idx" ON "enrollments"("school_year_id");

-- CreateIndex
CREATE INDEX "sessions_municipality_id_idx" ON "sessions"("municipality_id");

-- CreateIndex
CREATE INDEX "sessions_structure_id_date_idx" ON "sessions"("structure_id", "date");

-- CreateIndex
CREATE INDEX "sessions_program_id_date_idx" ON "sessions"("program_id", "date");

-- CreateIndex
CREATE INDEX "attendance_records_municipality_id_session_id_idx" ON "attendance_records"("municipality_id", "session_id");

-- CreateIndex
CREATE INDEX "attendance_records_child_id_idx" ON "attendance_records"("child_id");

-- CreateIndex
CREATE INDEX "meals_municipality_id_date_idx" ON "meals"("municipality_id", "date");

-- CreateIndex
CREATE INDEX "meals_child_id_idx" ON "meals"("child_id");

-- CreateIndex
CREATE INDEX "trips_municipality_id_date_idx" ON "trips"("municipality_id", "date");

-- CreateIndex
CREATE INDEX "trip_participations_child_id_idx" ON "trip_participations"("child_id");

-- CreateIndex
CREATE UNIQUE INDEX "trip_participations_trip_id_child_id_key" ON "trip_participations"("trip_id", "child_id");

-- CreateIndex
CREATE INDEX "passport_jeunes_child_id_idx" ON "passport_jeunes"("child_id");

-- CreateIndex
CREATE UNIQUE INDEX "passport_jeunes_municipality_id_number_key" ON "passport_jeunes"("municipality_id", "number");

-- CreateIndex
CREATE INDEX "pais_child_id_idx" ON "pais"("child_id");

-- CreateIndex
CREATE INDEX "handicap_followups_child_id_idx" ON "handicap_followups"("child_id");

-- CreateIndex
CREATE INDEX "documents_municipality_id_owner_type_owner_id_idx" ON "documents"("municipality_id", "owner_type", "owner_id");

-- CreateIndex
CREATE INDEX "notifications_recipient_user_id_read_at_idx" ON "notifications"("recipient_user_id", "read_at");

-- CreateIndex
CREATE UNIQUE INDEX "email_templates_municipality_id_key_key" ON "email_templates"("municipality_id", "key");

-- CreateIndex
CREATE INDEX "email_logs_municipality_id_status_created_at_idx" ON "email_logs"("municipality_id", "status", "created_at");

-- AddForeignKey
ALTER TABLE "municipalities" ADD CONSTRAINT "municipalities_community_id_fkey" FOREIGN KEY ("community_id") REFERENCES "communities"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "memberships" ADD CONSTRAINT "memberships_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permissions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "membership_structures" ADD CONSTRAINT "membership_structures_membership_id_fkey" FOREIGN KEY ("membership_id") REFERENCES "memberships"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "membership_structures" ADD CONSTRAINT "membership_structures_structure_id_fkey" FOREIGN KEY ("structure_id") REFERENCES "structures"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "structures" ADD CONSTRAINT "structures_neighborhood_id_fkey" FOREIGN KEY ("neighborhood_id") REFERENCES "neighborhoods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "holiday_periods" ADD CONSTRAINT "holiday_periods_school_year_id_fkey" FOREIGN KEY ("school_year_id") REFERENCES "school_years"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public_holidays" ADD CONSTRAINT "public_holidays_school_year_id_fkey" FOREIGN KEY ("school_year_id") REFERENCES "school_years"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "opening_hours" ADD CONSTRAINT "opening_hours_structure_id_fkey" FOREIGN KEY ("structure_id") REFERENCES "structures"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "programs" ADD CONSTRAINT "programs_structure_id_fkey" FOREIGN KEY ("structure_id") REFERENCES "structures"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pricing_tiers" ADD CONSTRAINT "pricing_tiers_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "programs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "families" ADD CONSTRAINT "families_neighborhood_id_fkey" FOREIGN KEY ("neighborhood_id") REFERENCES "neighborhoods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guardians" ADD CONSTRAINT "guardians_family_id_fkey" FOREIGN KEY ("family_id") REFERENCES "families"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "children" ADD CONSTRAINT "children_family_id_fkey" FOREIGN KEY ("family_id") REFERENCES "families"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "children" ADD CONSTRAINT "children_school_structure_id_fkey" FOREIGN KEY ("school_structure_id") REFERENCES "structures"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "children" ADD CONSTRAINT "children_neighborhood_id_fkey" FOREIGN KEY ("neighborhood_id") REFERENCES "neighborhoods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guardianships" ADD CONSTRAINT "guardianships_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guardianships" ADD CONSTRAINT "guardianships_guardian_id_fkey" FOREIGN KEY ("guardian_id") REFERENCES "guardians"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "enrollments" ADD CONSTRAINT "enrollments_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "enrollments" ADD CONSTRAINT "enrollments_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "programs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "enrollments" ADD CONSTRAINT "enrollments_school_year_id_fkey" FOREIGN KEY ("school_year_id") REFERENCES "school_years"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "programs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_structure_id_fkey" FOREIGN KEY ("structure_id") REFERENCES "structures"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meals" ADD CONSTRAINT "meals_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meals" ADD CONSTRAINT "meals_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_structure_id_fkey" FOREIGN KEY ("structure_id") REFERENCES "structures"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_participations" ADD CONSTRAINT "trip_participations_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_participations" ADD CONSTRAINT "trip_participations_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "passport_jeunes" ADD CONSTRAINT "passport_jeunes_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pais" ADD CONSTRAINT "pais_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "handicap_followups" ADD CONSTRAINT "handicap_followups_child_id_fkey" FOREIGN KEY ("child_id") REFERENCES "children"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

