#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Running Integration Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FRONTEND_URL="http://localhost:3000"
MAX_WAIT=60
INTERVAL=3
ELAPSED=0

# ── Step 1: Wait for frontend to be ready ────────────────────
echo "⏳ Waiting for frontend..."
until curl -sf "$FRONTEND_URL" > /dev/null; do
  if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "❌ Frontend never became ready"
    exit 1
  fi
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done
echo "✅ Frontend is up"

# ── Step 2: Submit a job ──────────────────────────────────────
echo "📤 Submitting job..."
RESPONSE=$(curl -sf -X POST "$FRONTEND_URL/submit" \
  -H "Content-Type: application/json")

echo "Response: $RESPONSE"
JOB_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['job_id'])")

if [ -z "$JOB_ID" ]; then
  echo "❌ No job_id returned"
  exit 1
fi
echo "✅ Job submitted: $JOB_ID"

# ── Step 3: Poll until completed ─────────────────────────────
echo "⏳ Polling job status..."
ELAPSED=0
while true; do
  STATUS_RESPONSE=$(curl -sf "$FRONTEND_URL/status/$JOB_ID")
  STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))")
  echo "  Status: $STATUS"

  if [ "$STATUS" = "completed" ]; then
    echo "✅ Job completed successfully"
    break
  fi

  if [ "$STATUS" = "failed" ]; then
    echo "❌ Job failed"
    exit 1
  fi

  if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "❌ Job did not complete within ${MAX_WAIT}s"
    exit 1
  fi

  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Integration Test PASSED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0
