# syntax=docker/dockerfile:1.6

# ---- deps: install only what package.json needs, cached on lockfile hash ----
FROM node:20-alpine AS deps
WORKDIR /app
# libc6-compat is needed for some Next.js native deps on Alpine.
RUN apk add --no-cache libc6-compat
COPY package.json package-lock.json* ./
RUN npm ci

# ---- builder: compile the app and produce the standalone bundle ----
FROM node:20-alpine AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# ---- runner: minimal runtime image, non-root user ----
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Run as a non-root user. Alpine's node image already provides `node` (uid 1000).
RUN addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 nextjs

# Public assets and the static chunks need to sit alongside the standalone server.
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000

# Container-level healthcheck. ECS / ALB will hit /api/health independently;
# this just protects local docker-compose runs.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --spider http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
