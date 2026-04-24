# ==============================================================
# Stage 1: Builder — install ALL deps including devDependencies
# ==============================================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files first (layer caching)
COPY package*.json ./

# Install everything including devDeps (needed for any build steps)
RUN npm ci

# Copy source
COPY . .


# ==============================================================
# Stage 2: Production — only production deps
# ==============================================================
FROM node:18-alpine

WORKDIR /app

# Non-root user (node image has built-in 'node' user — use it)
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup --no-create-home appuser

COPY package*.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Copy app source from builder
COPY --from=builder /app/app.js .
COPY --from=builder /app/views ./views

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })" || exit 1

CMD ["node", "app.js"]
