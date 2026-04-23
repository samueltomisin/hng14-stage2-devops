# ==============================================================
# Stage 1: Builder
# ==============================================================
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --user --no-cache-dir -r requirements.txt


# ==============================================================
# Stage 2: Production
# ==============================================================
FROM python:3.11-slim

WORKDIR /app

# Non-root user
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup --no-create-home appuser

# Copy packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy worker source
COPY worker.py .

RUN chown -R appuser:appgroup /app

USER appuser

ENV PATH=/home/appuser/.local/bin:$PATH

# Worker has no HTTP port — health check via Redis ping instead
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD python -c "import redis, os; r = redis.Redis(host=os.getenv('REDIS_HOST','redis'), port=int(os.getenv('REDIS_PORT',6379))); r.ping()" || exit 1

CMD ["python", "worker.py"]
