'use client';

import { useEffect, useState } from 'react';

type HealthResponse = {
  status: 'ok';
  uptime: number;
  env: string;
};

// Client component: demonstrates browser->API round-trip against the same /api/health
// endpoint the load balancer uses. Same code path, fewer surprises in prod.
export function HealthBadge() {
  const [data, setData] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();

    fetch('/api/health', { signal: controller.signal, cache: 'no-store' })
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json() as Promise<HealthResponse>;
      })
      .then(setData)
      .catch((e: unknown) => {
        if (e instanceof Error && e.name !== 'AbortError') setError(e.message);
      });

    return () => controller.abort();
  }, []);

  if (error) {
    return <span className="text-red-400">unreachable: {error}</span>;
  }

  if (!data) {
    return <span className="text-zinc-500">checking…</span>;
  }

  return (
    <dl className="grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
      <dt className="text-zinc-500">status</dt>
      <dd className="font-mono text-emerald-400">{data.status}</dd>
      <dt className="text-zinc-500">env</dt>
      <dd className="font-mono">{data.env}</dd>
      <dt className="text-zinc-500">uptime</dt>
      <dd className="font-mono">{data.uptime.toFixed(1)}s</dd>
    </dl>
  );
}
