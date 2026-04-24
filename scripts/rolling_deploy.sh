#!/bin/bash
set -e

# ── Config ────────────────────────────────────────────────────
SERVICES=("api" "worker" "frontend")
TIMEOUT=60
INTERVAL=5
IMAGE_TAG="${GITHUB_SHA:-latest}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Rolling Deploy — tag: $IMAGE_TAG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "🚀 Deploying $SERVICE..."

  # Pull new image
  docker compose pull "$SERVICE" || true

  # Start new container alongside old one
  docker compose up -d --no-deps --scale "${SERVICE}=2" "$SERVICE" 2>/dev/null || \
  docker compose up -d --no-deps "$SERVICE"

  # Wait for health check to pass
  ELAPSED=0
  echo "⏳ Waiting for $SERVICE to become healthy..."

  until [ "$(docker inspect --format='{{.State.Health.Status}}' \
    "$(docker compose ps -q "$SERVICE" | head -1)")" = "healthy" ]; do

    if [ $ELAPSED -ge $TIMEOUT ]; then
      echo "❌ $SERVICE health check failed after ${TIMEOUT}s"
      echo "   Aborting deploy — old container still running"
      # Scale back down to 1 (keeps old container)
      docker compose up -d --no-deps --scale "${SERVICE}=1" "$SERVICE" 2>/dev/null || true
      exit 1
    fi

    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
  done

  echo "✅ $SERVICE is healthy — removing old container"
  docker compose up -d --no-deps --scale "${SERVICE}=1" "$SERVICE" 2>/dev/null || true

done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Rolling Deploy Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
