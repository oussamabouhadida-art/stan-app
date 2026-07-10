import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

/**
 * The base (unscoped) Prisma client — singleton.
 * Business code must NOT use this for tenant data; it wraps it with the tenant-scoped
 * extension via createTenantClient(ctx). Use the base client only for global tables
 * (User, Municipality, Permission) and platform operations. See docs/multi-tenancy.md.
 */
export const prisma: PrismaClient = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
