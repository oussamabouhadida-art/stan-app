'use client';

import { useTheme } from 'next-themes';
import { Bell, Building2, ChevronDown, Moon, Search, Sun } from 'lucide-react';
import { Button } from '@stan/ui';

export function AppTopbar() {
  const { resolvedTheme, setTheme } = useTheme();

  return (
    <header className="flex h-14 items-center gap-2 border-b px-3 md:px-4">
      <button
        type="button"
        className="bg-card hover:bg-accent flex items-center gap-2 rounded-md border px-3 py-1.5 text-sm transition-colors"
      >
        <Building2 className="text-muted-foreground size-4" aria-hidden="true" />
        Ville-Exemple
        <ChevronDown className="text-muted-foreground size-4" aria-hidden="true" />
      </button>

      <div className="relative ml-1 hidden max-w-md flex-1 sm:block">
        <Search
          className="text-muted-foreground pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2"
          aria-hidden="true"
        />
        <input
          type="search"
          placeholder="Rechercher une famille, un enfant…"
          aria-label="Rechercher"
          className="bg-background placeholder:text-muted-foreground focus-visible:ring-ring h-9 w-full rounded-md border pl-9 pr-3 text-sm outline-none transition-shadow focus-visible:ring-2"
        />
      </div>

      <div className="flex-1" />

      <Button
        variant="ghost"
        size="icon"
        aria-label="Changer de thème"
        onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
      >
        <Sun className="size-[18px] dark:hidden" aria-hidden="true" />
        <Moon className="hidden size-[18px] dark:block" aria-hidden="true" />
      </Button>
      <Button variant="ghost" size="icon" aria-label="Notifications">
        <Bell className="size-[18px]" aria-hidden="true" />
      </Button>
      <div className="bg-primary/10 text-primary flex size-8 items-center justify-center rounded-full text-xs font-medium">
        MB
      </div>
    </header>
  );
}
