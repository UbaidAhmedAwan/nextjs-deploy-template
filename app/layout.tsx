import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: process.env.NEXT_PUBLIC_APP_NAME ?? 'Next.js Deploy Template',
  description: 'Next.js App Router starter with Docker + ECS deployment pipeline.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-zinc-950 text-zinc-100 antialiased">{children}</body>
    </html>
  );
}
