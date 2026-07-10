import type { Metadata } from 'next';
import { Settings } from 'lucide-react';
import { ComingSoon } from '@/shared/components/coming-soon';

export const metadata: Metadata = { title: 'Administration' };

export default function AdministrationPage() {
  return (
    <ComingSoon
      title="Administration"
      description="Le cœur de Stan : identité de la commune, structures, rôles, permissions et modules — tout configurable sans code."
      icon={<Settings className="size-8" aria-hidden="true" />}
    />
  );
}
