import type { Metadata } from 'next';
import { Check } from 'lucide-react';
import { Badge, Button, Card } from '@stan/ui';
import { StatCard } from '@/shared/components/stat-card';

export const metadata: Metadata = { title: 'Présences' };

type Status = 'present' | 'absent' | 'pending';
type Row = { name: string; group: string; initials: string; status: Status; time?: string };

const children: Row[] = [
  {
    name: 'Emma Laurent',
    group: 'Groupe des Lutins',
    initials: 'EL',
    status: 'present',
    time: '08:12',
  },
  {
    name: 'Noah Petit',
    group: 'Groupe des Lutins',
    initials: 'NP',
    status: 'present',
    time: '08:20',
  },
  { name: 'Jade Moreau', group: 'Groupe des Renards', initials: 'JM', status: 'absent' },
  { name: 'Louis Girard', group: 'Groupe des Renards', initials: 'LG', status: 'pending' },
  {
    name: 'Camille Roy',
    group: 'Groupe des Lutins',
    initials: 'CR',
    status: 'present',
    time: '08:05',
  },
  {
    name: 'Adam Fontaine',
    group: 'Groupe des Renards',
    initials: 'AF',
    status: 'present',
    time: '08:31',
  },
  { name: 'Chloé Dubois', group: 'Groupe des Lutins', initials: 'CD', status: 'pending' },
];

function StatusCell({ row }: { row: Row }) {
  if (row.status === 'present') return <Badge variant="success">Présent·e</Badge>;
  if (row.status === 'absent') return <Badge variant="destructive">Absent·e</Badge>;
  return (
    <Button variant="outline" size="sm">
      <Check className="size-4" aria-hidden="true" />
      Pointer
    </Button>
  );
}

export default function PresencesPage() {
  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-start gap-3">
        <div className="min-w-0 flex-1">
          <h1 className="text-xl font-medium">Présences</h1>
          <p className="text-muted-foreground text-sm">
            mercredi 15 janvier · Centre de loisirs du Centre
          </p>
        </div>
        <Button>
          <Check className="size-4" aria-hidden="true" />
          Enregistrer
        </Button>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <StatCard label="Présents" value="84" />
        <StatCard label="Absents" value="12" />
        <StatCard label="Taux de présence" value="87 %" />
      </div>

      <Card className="overflow-hidden">
        <div className="flex items-center justify-between px-4 py-3">
          <span className="text-sm font-medium">Enfants inscrits</span>
          <span className="text-muted-foreground text-xs">96 enfants</span>
        </div>
        <ul className="border-t">
          {children.map((row) => (
            <li
              key={row.name}
              className="flex items-center gap-3 border-t px-4 py-2.5 first:border-t-0"
            >
              <div className="bg-muted text-muted-foreground flex size-9 shrink-0 items-center justify-center rounded-full text-xs font-medium">
                {row.initials}
              </div>
              <div className="min-w-0 flex-1">
                <div className="truncate text-sm font-medium">{row.name}</div>
                <div className="text-muted-foreground text-xs">{row.group}</div>
              </div>
              {row.time ? (
                <span className="text-muted-foreground hidden text-xs sm:inline">
                  Arrivé·e {row.time}
                </span>
              ) : null}
              <StatusCell row={row} />
            </li>
          ))}
        </ul>
      </Card>
    </div>
  );
}
