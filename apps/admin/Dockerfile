# syntax=docker/dockerfile:1

# ============================================
# Base stage - Common dependencies
# ============================================
FROM node:18-alpine AS base
WORKDIR /app

# Install libc6-compat for Alpine compatibility
RUN apk add --no-cache libc6-compat

# ============================================
# Dependencies stage - Install all dependencies
# ============================================
FROM base AS deps

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# ============================================
# Development stage - Hot reload enabled
# ============================================
FROM base AS dev

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Start dev server
CMD ["npm", "run", "dev"]

# ============================================
# Builder stage - Build production application
# ============================================
FROM base AS builder

# Accept build arguments for NEXT_PUBLIC variables
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Copy dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

# Build application (NEXT_PUBLIC_API_URL gets baked in)
RUN npm run build

# ============================================
# Production stage - Minimal runtime image
# ============================================
FROM node:18-alpine AS prod

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

# Copy built application from builder
# standalone output includes minimal node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set hostname to 0.0.0.0 to accept connections from outside container
ENV HOSTNAME="0.0.0.0"

# Start production server
CMD ["node", "server.js"]
