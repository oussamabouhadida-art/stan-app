import type { PrismaClient } from '@prisma/client';
import {
  isSoftDeletable,
  isTenantScoped,
  TenantContextError,
  type TenantContext,
} from '@stan/core';

/**
 * Wall 1 of tenant isolation (see docs/multi-tenancy.md).
 *
 * A Prisma client extension that, for every tenant-scoped model:
 *  - injects `municipalityId` on create/createMany,
 *  - constrains every read/update/delete `where` to the current municipality,
 *  - auto-excludes soft-deleted rows,
 *  - throws on any attempt to write/target a foreign `municipalityId`.
 *
 * Repositories only ever receive a client built by `createTenantClient(ctx)`, so an
 * unscoped tenant query is structurally impossible.
 */

type Args = Record<string, unknown>;

const UNIQUE_OPS = new Set(['findUnique', 'findUniqueOrThrow', 'update', 'delete']);
const FILTER_OPS = new Set([
  'findFirst',
  'findFirstOrThrow',
  'findMany',
  'updateMany',
  'deleteMany',
  'count',
  'aggregate',
  'groupBy',
]);

function assertSameTenant(municipalityId: string, obj: Args): void {
  const mid = obj['municipalityId'];
  if (typeof mid === 'string' && mid !== municipalityId) {
    throw new TenantContextError('Opération inter-commune bloquée');
  }
}

function tenantConstraint(municipalityId: string, soft: boolean): Args {
  return soft ? { municipalityId, deletedAt: null } : { municipalityId };
}

export function createTenantClient(base: PrismaClient, ctx: TenantContext) {
  return base.$extends({
    name: 'stan-tenant-scope',
    query: {
      $allModels: {
        $allOperations({ model, operation, args, query }) {
          if (!model || !isTenantScoped(model)) {
            return query(args);
          }

          const soft = isSoftDeletable(model);
          // Prisma types extension `args` as `any`; narrow it explicitly for our helpers.
          // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
          const a: Args = (args as Args | undefined) ?? {};
          const constraint = tenantConstraint(ctx.municipalityId, soft);

          if (operation === 'create') {
            const data = (a['data'] as Args | undefined) ?? {};
            assertSameTenant(ctx.municipalityId, data);
            a['data'] = { ...data, municipalityId: ctx.municipalityId };
          } else if (operation === 'createMany') {
            const data = a['data'] as Args | Args[] | undefined;
            const rows: Args[] = Array.isArray(data) ? data : [data ?? {}];
            a['data'] = rows.map((row) => {
              assertSameTenant(ctx.municipalityId, row);
              return { ...row, municipalityId: ctx.municipalityId };
            });
          } else if (operation === 'upsert') {
            throw new TenantContextError(
              `upsert non supporté sous scope commune (${model}) — utiliser find puis create/update`,
            );
          } else if (UNIQUE_OPS.has(operation)) {
            const where = (a['where'] as Args | undefined) ?? {};
            assertSameTenant(ctx.municipalityId, where);
            a['where'] = { ...where, ...constraint };
            if (operation === 'update') {
              assertSameTenant(ctx.municipalityId, (a['data'] as Args | undefined) ?? {});
            }
          } else if (FILTER_OPS.has(operation)) {
            const where = a['where'];
            a['where'] = where ? { AND: [where, constraint] } : constraint;
            if (operation === 'updateMany') {
              assertSameTenant(ctx.municipalityId, (a['data'] as Args | undefined) ?? {});
            }
          }

          return query(a);
        },
      },
    },
  });
}

export type TenantClient = ReturnType<typeof createTenantClient>;
