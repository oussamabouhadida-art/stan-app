/**
 * The registry of tenant-scoped models. The tenant Prisma extension (@stan/db) uses
 * this to auto-inject `municipalityId` and to make an unscoped tenant query impossible.
 *
 * NOT tenant-scoped (global or the tenant root): Community, Municipality, User, Permission.
 * Adding a new model with a `municipality_id` column MUST be reflected here — a CI check
 * asserts the two stay in sync. See docs/multi-tenancy.md §6.
 */
export const TENANT_SCOPED_MODELS = new Set<string>([
  // Foundation
  'Membership',
  'Role',
  'RolePermission',
  'MembershipStructure',
  'AuditLog',
  'Setting',
  'MunicipalityModule',
  'EmailDomain',
  // Configuration
  'Neighborhood',
  'Structure',
  'SchoolYear',
  'HolidayPeriod',
  'PublicHoliday',
  'OpeningHour',
  'Program',
  'PricingTier',
  'CafIndicator',
  // People
  'Family',
  'Guardian',
  'Child',
  'Guardianship',
  'Enrollment',
  // Operations
  'Session',
  'AttendanceRecord',
  'Meal',
  'Trip',
  'TripParticipation',
  'PassportJeune',
  'Pai',
  'HandicapFollowup',
  'Document',
  'Notification',
  'EmailTemplate',
  'EmailLog',
]);

/** Tenant-scoped models that carry a `deleted_at` column (soft delete auto-filtering). */
export const SOFT_DELETE_MODELS = new Set<string>([
  'Membership',
  'Role',
  'Neighborhood',
  'Structure',
  'Program',
  'Family',
  'Guardian',
  'Child',
  'Enrollment',
  'AttendanceRecord',
  'Trip',
  'Pai',
  'HandicapFollowup',
  'Document',
]);

export function isTenantScoped(model: string): boolean {
  return TENANT_SCOPED_MODELS.has(model);
}

export function isSoftDeletable(model: string): boolean {
  return SOFT_DELETE_MODELS.has(model);
}
