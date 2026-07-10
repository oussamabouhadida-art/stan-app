import type { Metadata } from 'next';
import { CalendarDays } from 'lucide-react';
import { ComingSoon } from '@/shared/components/coming-soon';

export const metadata: Metadata = { title: 'Activités' };

export default function ActivitesPage() {
  return (
    <ComingSoon
      title="Activités"
      description="Programmes, ateliers, séances et inscriptions par année scolaire."
      icon={<CalendarDays className="size-8" aria-hidden="true" />}
    />
  );
}
