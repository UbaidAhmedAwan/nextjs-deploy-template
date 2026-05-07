import { NextResponse } from 'next/server';

// Force dynamic so this isn't statically rendered at build time -
// uptime/env need to reflect the running container, not the build host.
export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

export function GET() {
  return NextResponse.json(
    {
      status: 'ok' as const,
      uptime: process.uptime(),
      env: process.env.NODE_ENV ?? 'development',
    },
    { headers: { 'Cache-Control': 'no-store' } },
  );
}
