# ==============================================================
# Stage 1: Builder — install dependencies only
# ==============================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy requirements
COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --user --no-cache-dir -r requirements.txt


# ==============================================================
# Stage 2: Production — lean final image, no build tools
# ==============================================================
FROM python:3.11-slim

WORKDIR /app

# Create non-root user and group
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup --no-create-home appuser

# Copy installed packages from builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Copy application source (no .env, no secrets)
COPY main.py .
COPY requirements.txt .

# Fix ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Make sure installed packages are on PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Expose app port
EXPOSE 8000

# Health check — hits the /health endpoint we added
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
