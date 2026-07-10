/**
 * The server-resolved identity + tenant scope for a request.
 * Built once per request from the Supabase session + active membership, then passed
 * explicitly into services. Never read from a global. See docs/multi-tenancy.md.
 */
export interface TenantContext {
  readonly userId: string;
  readonly municipalityId: string;
  readonly membershipId: string;
  readonly roleId: string;
  readonly permissions: ReadonlySet<string>;
  readonly isSuperAdmin: boolean;
}

/** Authorization helper — throws ForbiddenError if the actor lacks the permission. */
export function can(ctx: TenantContext, permission: string): boolean {
  return ctx.permissions.has(permission);
}
