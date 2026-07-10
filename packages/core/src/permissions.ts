/**
 * The global permission catalog — the fixed vocabulary of capabilities checked in code
 * (`domain.action`). Code checks these keys, never role names. Roles (per municipality)
 * compose them. Seeded into the `permissions` table. See docs/authorization-rbac.md.
 */
export const PERMISSIONS = [
  { key: 'family.read', domain: 'family', description: 'Consulter les familles' },
  { key: 'family.write', domain: 'family', description: 'Créer et modifier les familles' },
  { key: 'child.read', domain: 'child', description: 'Consulter les enfants' },
  { key: 'child.write', domain: 'child', description: 'Créer et modifier les enfants' },
  { key: 'attendance.read', domain: 'attendance', description: 'Consulter les présences' },
  { key: 'attendance.write', domain: 'attendance', description: 'Enregistrer les présences' },
  { key: 'meal.read', domain: 'meal', description: 'Consulter les repas' },
  { key: 'meal.write', domain: 'meal', description: 'Gérer les repas' },
  { key: 'trip.read', domain: 'trip', description: 'Consulter les sorties' },
  { key: 'trip.write', domain: 'trip', description: 'Gérer les sorties' },
  { key: 'activity.read', domain: 'activity', description: 'Consulter les activités' },
  {
    key: 'activity.manage',
    domain: 'activity',
    description: 'Gérer activités, programmes et séances',
  },
  { key: 'pai.read', domain: 'pai', description: 'Consulter les PAI (donnée sensible)' },
  { key: 'pai.write', domain: 'pai', description: 'Gérer les PAI (donnée sensible)' },
  {
    key: 'handicap.read',
    domain: 'handicap',
    description: 'Consulter le suivi handicap (donnée sensible)',
  },
  {
    key: 'handicap.write',
    domain: 'handicap',
    description: 'Gérer le suivi handicap (donnée sensible)',
  },
  { key: 'document.read', domain: 'document', description: 'Consulter les documents' },
  { key: 'document.write', domain: 'document', description: 'Gérer les documents' },
  {
    key: 'report.view',
    domain: 'report',
    description: 'Accéder aux tableaux de bord et statistiques',
  },
  { key: 'audit.read', domain: 'audit', description: "Consulter le journal d'audit" },
  { key: 'admin.config', domain: 'admin', description: 'Modifier la configuration de la commune' },
  {
    key: 'admin.access',
    domain: 'admin',
    description: 'Gérer les rôles, permissions et utilisateurs',
  },
  { key: 'admin.tools', domain: 'admin', description: 'Outils de maintenance (import/export)' },
  {
    key: 'municipality.provision',
    domain: 'platform',
    description: 'Installer et gérer les communes (super-admin)',
  },
] as const;

export type PermissionDefinition = (typeof PERMISSIONS)[number];
export type PermissionKey = PermissionDefinition['key'];

export const PERMISSION_KEYS: readonly PermissionKey[] = PERMISSIONS.map((p) => p.key);
