import type { ReactNode } from 'react';
import { Card } from '@stan/ui';

export function StatCard({
  label,
  value,
  hint,
  icon,
}: {
  label: string;
  value: string;
  hint?: string;
  icon?: ReactNode;
}) {
  return (
    <Card className="p-4">
      <div className="flex items-center justify-between">
        <span className="text-muted-foreground text-sm">{label}</span>
        {icon ? <span className="text-muted-foreground">{icon}</span> : null}
      </div>
      <div className="mt-2 text-2xl font-medium tabular-nums">{value}</div>
      {hint ? <div className="text-muted-foreground mt-1 text-xs">{hint}</div> : null}
    </Card>
  );
}
