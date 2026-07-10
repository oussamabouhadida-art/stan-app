import type { Prisma, PrismaClient } from '@prisma/client';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Wall 2 of tenant isolation (see docs/multi-tenancy.md).
 *
 * Runs `fn` inside a transaction that first sets `app.current_municipality`, which the
 * Postgres Row-Level Security policies read. This is the database-level backstop: even a
 * bug in Wall 1 (the app extension) or raw SQL cannot cross municipalities.
 *
 * Effective only when the app connects via a role WITHOUT the BYPASSRLS attribute — the
 * dedicated application role is provisioned when the auth layer is wired (Phase 3).
 */
export async function withTenantRls<T>(
  base: PrismaClient,
  municipalityId: string,
  fn: (tx: Prisma.TransactionClient) => Promise<T>,
): Promise<T> {
  if (!UUID_RE.test(municipalityId)) {
    throw new Error('municipalityId invalide');
  }
  return base.$transaction(async (tx) => {
    await tx.$executeRaw`SELECT set_config('app.current_municipality', ${municipalityId}, true)`;
    return fn(tx);
  });
}
