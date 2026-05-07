import { HealthBadge } from './_components/health-badge';

// Server component: reads env on the server so we don't ship NODE_ENV decisions to the client.
export default function HomePage() {
  const appName = process.env.NEXT_PUBLIC_APP_NAME ?? 'Next.js Deploy Template';

  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col justify-center gap-8 p-8">
      <header className="space-y-2">
        <h1 className="text-3xl font-semibold tracking-tight">{appName}</h1>
        <p className="text-zinc-400">
          App Router starter with a Dockerised standalone build and an ECS deploy pipeline.
        </p>
      </header>

      <section className="rounded-lg border border-zinc-800 bg-zinc-900/50 p-6">
        <h2 className="mb-3 text-sm font-medium uppercase tracking-wide text-zinc-400">
          Runtime status
        </h2>
        <HealthBadge />
      </section>

      <footer className="text-xs text-zinc-500">
        <code className="rounded bg-zinc-900 px-2 py-1">GET /api/health</code>
        <span className="ml-2">is the ALB health-check endpoint.</span>
      </footer>
    </main>
  );
}
