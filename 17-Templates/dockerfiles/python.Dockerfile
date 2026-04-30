# Multi-stage Python build
# - uv ile hızlı dependency install (pip'ten 10-100x hızlı)
# - Distroless'a yakın final imaj
#
# Alternatif paketleyici: uv (Astral) | poetry | pip

# ----- Stage 1: Build venv -----
FROM python:3.12-slim AS build

# uv kurulum (Astral'in modern Python paketleyicisi)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Bağımlılıkları yükle (cache friendly)
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Uygulama kodunu kopyala
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# ----- Stage 2: Runtime -----
FROM python:3.12-slim AS runtime

# Güvenlik: non-root user
RUN groupadd -r app -g 65532 && \
    useradd -r -g app -u 65532 -m -d /home/app app && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# venv ve uygulama kodu
COPY --from=build --chown=app:app /app /app

# venv'i path'e ekle
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random

USER app

EXPOSE 8000

# uvicorn / gunicorn / fastapi
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# ───────────────────────────────────────────────────────────
# Alternatif: Chainguard
#
# FROM cgr.dev/chainguard/python:latest AS runtime
# WORKDIR /app
# COPY --from=build --chown=nonroot:nonroot /app /app
# ENV PATH="/app/.venv/bin:$PATH"
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
