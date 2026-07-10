import type { Metadata } from 'next';
import { Baby } from 'lucide-react';
import { ComingSoon } from '@/shared/components/coming-soon';

export const metadata: Metadata = { title: 'Enfants' };

export default function EnfantsPage() {
  return (
    <ComingSoon
      title="Enfants"
      description="Fiches des enfants et des jeunes, inscriptions, PAI et suivi handicap."
      icon={<Baby className="size-8" aria-hidden="true" />}
    />
  );
}
