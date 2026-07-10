import type { LucideIcon } from 'lucide-react';
import {
  Baby,
  Bus,
  CalendarDays,
  ClipboardCheck,
  LayoutDashboard,
  Settings,
  UsersRound,
  UtensilsCrossed,
} from 'lucide-react';

export type NavItem = {
  label: string;
  href: string;
  icon: LucideIcon;
};

export const mainNav: NavItem[] = [
  { label: 'Tableau de bord', href: '/dashboard', icon: LayoutDashboard },
  { label: 'Familles', href: '/familles', icon: UsersRound },
  { label: 'Enfants', href: '/enfants', icon: Baby },
  { label: 'Présences', href: '/presences', icon: ClipboardCheck },
  { label: 'Activités', href: '/activites', icon: CalendarDays },
  { label: 'Repas', href: '/repas', icon: UtensilsCrossed },
  { label: 'Sorties', href: '/sorties', icon: Bus },
];

export const adminNav: NavItem[] = [
  { label: 'Administration', href: '/administration', icon: Settings },
];
