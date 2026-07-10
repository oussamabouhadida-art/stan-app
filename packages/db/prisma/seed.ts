import { PERMISSIONS } from '@stan/core';
import { PrismaClient } from '@prisma/client';

/**
 * Seeds the GLOBAL permission catalog (idempotent). Roles are per-municipality and are
 * created during municipality provisioning, not here. See docs/authorization-rbac.md.
 */
const prisma = new PrismaClient();

async function main(): Promise<void> {
  for (const permission of PERMISSIONS) {
    await prisma.permission.upsert({
      where: { key: permission.key },
      create: {
        key: permission.key,
        domain: permission.domain,
        description: permission.description,
      },
      update: { domain: permission.domain, description: permission.description },
    });
  }
  console.warn(`Seeded ${String(PERMISSIONS.length)} permissions.`);
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => {
    void prisma.$disconnect();
  });
