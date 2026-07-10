import type { Metadata } from 'next';
import { Baby, Bus, ClipboardCheck, TrendingUp, UsersRound } from 'lucide-react';
import { Badge, Card, CardContent, CardHeader, CardTitle } from '@stan/ui';
import { StatCard } from '@/shared/components/stat-card';

export const metadata: Metadata = { title: 'Tableau de bord' };

const recentActivity = [
  { who: 'Léa Martin', what: 'a enregistré les présences du matin', when: 'il y a 8 min' },
  {
    who: 'Karim Benali',
    what: 'a inscrit Emma Laurent au Stage Multisports',
    when: 'il y a 32 min',
  },
  { who: 'Marie Durand', what: 'a modifié les horaires du Centre du Centre', when: 'il y a 1 h' },
  { who: 'Léa Martin', what: 'a signalé une absence pour Jade Moreau', when: 'il y a 2 h' },
];

const upcomingTrips = [
  { name: 'Musée en herbe', date: '18 janv.', places: '24 / 24' },
  { name: 'Ferme pédagogique', date: '25 janv.', places: '18 / 30' },
  { name: 'Piscine municipale', date: '1 févr.', places: '20 / 20' },
];

export default function DashboardPage() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-xl font-medium">Tableau de bord</h1>
        <p className="text-muted-foreground text-sm">Ville-Exemple · mercredi 15 janvier</p>
      </div>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard
          label="Enfants inscrits"
          value="96"
          hint="+4 cette semaine"
          icon={<Baby className="size-[18px]" />}
        />
        <StatCard
          label="Présents aujourd'hui"
          value="84"
          hint="sur 96 inscrits"
          icon={<ClipboardCheck className="size-[18px]" />}
        />
        <StatCard
          label="Taux de présence"
          value="87 %"
          hint="+2 pts vs hier"
          icon={<TrendingUp className="size-[18px]" />}
        />
        <StatCard
          label="Familles"
          value="71"
          hint="réparties sur 12 quartiers"
          icon={<UsersRound className="size-[18px]" />}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Activité récente</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col">
            {recentActivity.map((item, i) => (
              <div
                key={i}
                className="flex items-center gap-3 border-t py-3 first:border-t-0 first:pt-0"
              >
                <div className="bg-muted text-muted-foreground flex size-8 shrink-0 items-center justify-center rounded-full text-xs font-medium">
                  {item.who
                    .split(' ')
                    .map((n) => n[0])
                    .join('')}
                </div>
                <p className="min-w-0 flex-1 text-sm">
                  <span className="font-medium">{item.who}</span>{' '}
                  <span className="text-muted-foreground">{item.what}</span>
                </p>
                <span className="text-muted-foreground shrink-0 text-xs">{item.when}</span>
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Prochaines sorties</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col">
            {upcomingTrips.map((trip, i) => (
              <div
                key={i}
                className="flex items-center gap-3 border-t py-3 first:border-t-0 first:pt-0"
              >
                <div className="bg-primary/10 text-primary flex size-8 shrink-0 items-center justify-center rounded-lg">
                  <Bus className="size-4" aria-hidden="true" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-medium">{trip.name}</div>
                  <div className="text-muted-foreground text-xs">{trip.date}</div>
                </div>
                <Badge
                  variant={
                    trip.places.split(' / ')[0] === trip.places.split(' / ')[1]
                      ? 'warning'
                      : 'secondary'
                  }
                >
                  {trip.places}
                </Badge>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
