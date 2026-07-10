import type { ReactNode } from 'react';

export function ComingSoon({
  title,
  description,
  icon,
}: {
  title: string;
  description: string;
  icon?: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1">
      <h1 className="text-xl font-medium">{title}</h1>
      <p className="text-muted-foreground text-sm">{description}</p>
      <div className="mt-6 flex flex-col items-center justify-center gap-3 rounded-xl border border-dashed p-12 text-center">
        {icon ? <span className="text-muted-foreground">{icon}</span> : null}
        <p className="text-muted-foreground max-w-sm text-sm">
          Ce module sera livré dans une prochaine étape, une fois la base de données connectée.
        </p>
      </div>
    </div>
  );
}
