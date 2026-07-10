import type { Metadata } from 'next';
import { UtensilsCrossed } from 'lucide-react';
import { ComingSoon } from '@/shared/components/coming-soon';

export const metadata: Metadata = { title: 'Repas' };

export default function RepasPage() {
  return (
    <ComingSoon
      title="Repas"
      description="Planification des repas, régimes alimentaires et effectifs prévisionnels."
      icon={<UtensilsCrossed className="size-8" aria-hidden="true" />}
    />
  );
}
