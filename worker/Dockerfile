# ==============================================================
# Stage 1: Builder
# ==============================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Create virtual environment 
RUN python -m venv /opt/venv

# Activate venv by putting it first on PATH
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install  --no-cache-dir --upgrade pip==26.0.1 && \
    pip install --no-cache-dir -r requirements.txt

# ==============================================================
# Stage 2: Production
# ==============================================================
FROM python:3.11-slim

WORKDIR /app

# Create non-root user
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup --no-create-home appuser

# Copy the entire venv from builder — not /root/.local
COPY --from=builder /opt/venv /opt/venv

# Copy worker source
COPY worker.py .

# Fix ownership of app files
RUN chown -R appuser:appgroup /app

# Switch to non-root
USER appuser

# Activate venv in final stage
ENV PATH="/opt/venv/bin:$PATH"

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD python -c "import redis, os; r = redis.Redis(host=os.getenv('REDIS_HOST','redis'), port=int(os.getenv('REDIS_PORT',6379))); r.ping()" || exit 1

CMD ["python", "worker.py"]
