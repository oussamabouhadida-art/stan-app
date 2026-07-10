import type { Metadata } from 'next';
import { Bus } from 'lucide-react';
import { ComingSoon } from '@/shared/components/coming-soon';

export const metadata: Metadata = { title: 'Sorties' };

export default function SortiesPage() {
  return (
    <ComingSoon
      title="Sorties"
      description="Organisation des sorties, capacités et participations des enfants."
      icon={<Bus className="size-8" aria-hidden="true" />}
    />
  );
}
