import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import { GeistSans } from 'geist/font/sans';
import { GeistMono } from 'geist/font/mono';
import { ThemeProvider } from '@/shared/providers/theme-provider';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'Stan',
    template: '%s · Stan',
  },
  description:
    'Plateforme de gestion Enfance, Jeunesse, Périscolaire et Vacances pour les collectivités.',
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html
      lang="fr"
      suppressHydrationWarning
      className={`${GeistSans.variable} ${GeistMono.variable}`}
    >
      <body className="bg-background text-foreground min-h-screen font-sans antialiased">
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
