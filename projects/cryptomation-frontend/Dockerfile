# Build context: cryptomation-frontend/ (sibling Next.js project)
# This Dockerfile is invoked from cryptomation-bootstrap, not from the source.

# -----------------------------------------------------------------------------
# base — shared foundation
# -----------------------------------------------------------------------------
FROM node:24-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app

# -----------------------------------------------------------------------------
# deps — install dependencies (cached independently from source changes)
# -----------------------------------------------------------------------------
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci

# -----------------------------------------------------------------------------
# development — live-reload dev server
#
# Targeted by docker-compose.yml: build.target: development
#
# At runtime docker compose:
#   1. Bind-mounts cryptomation-frontend/ → /app  (source code)
#   2. Mounts named volume frontend_node_modules → /app/node_modules
#
# The named volume is populated from this image layer on first container start,
# so the container always uses its own npm-installed packages.
#
# When package.json changes:
#   docker compose down -v && docker compose up --build -d
# -----------------------------------------------------------------------------
FROM base AS development
COPY --from=deps /app/node_modules ./node_modules
ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
EXPOSE 3000
CMD ["npm", "run", "dev"]

# -----------------------------------------------------------------------------
# builder — production build (for CI or staging)
# -----------------------------------------------------------------------------
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# -----------------------------------------------------------------------------
# production — minimal runtime
#
# Requires next.config.ts:  output: 'standalone'
# Without that option, use the builder stage with CMD ["npm", "start"] instead.
# -----------------------------------------------------------------------------
FROM node:24-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs \
 && adduser  --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
