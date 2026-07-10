import type { Metadata } from 'next';
import { UsersRound } from 'lucide-react';
import { ComingSoon } from '@/shared/components/coming-soon';

export const metadata: Metadata = { title: 'Familles' };

export default function FamillesPage() {
  return (
    <ComingSoon
      title="Familles"
      description="Ménages, responsables légaux, coordonnées et quotient familial."
      icon={<UsersRound className="size-8" aria-hidden="true" />}
    />
  );
}
