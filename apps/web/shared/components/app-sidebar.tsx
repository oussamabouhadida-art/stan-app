'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@stan/ui';
import { adminNav, mainNav, type NavItem } from '@/shared/lib/nav';

function NavLink({ item, active }: { item: NavItem; active: boolean }) {
  const Icon = item.icon;
  return (
    <Link
      href={item.href}
      aria-current={active ? 'page' : undefined}
      className={cn(
        'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
        active
          ? 'bg-primary/10 text-primary'
          : 'text-muted-foreground hover:bg-sidebar-accent hover:text-foreground',
      )}
    >
      <Icon className="size-[18px] shrink-0" aria-hidden="true" />
      {item.label}
    </Link>
  );
}

export function AppSidebar() {
  const pathname = usePathname();
  const isActive = (href: string) => pathname === href || pathname.startsWith(`${href}/`);

  return (
    <aside className="bg-sidebar hidden w-60 shrink-0 flex-col border-r p-3 md:flex">
      <div className="flex items-center gap-2 px-2 py-3">
        <div className="bg-primary text-primary-foreground flex size-7 items-center justify-center rounded-lg text-sm font-medium">
          S
        </div>
        <span className="text-[15px] font-medium">Stan</span>
      </div>
      <nav className="flex flex-1 flex-col gap-0.5" aria-label="Navigation principale">
        {mainNav.map((item) => (
          <NavLink key={item.href} item={item} active={isActive(item.href)} />
        ))}
      </nav>
      <nav className="flex flex-col gap-0.5 border-t pt-2" aria-label="Administration">
        {adminNav.map((item) => (
          <NavLink key={item.href} item={item} active={isActive(item.href)} />
        ))}
      </nav>
    </aside>
  );
}
