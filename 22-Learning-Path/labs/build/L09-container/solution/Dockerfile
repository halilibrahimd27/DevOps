# Dockerfile (referans çözüm) — multi-stage, non-root, cache dostu.
# Önce KENDİN dene. Bu, starter/Dockerfile.naive'in "sonra" hâlidir.

# --- build stage: bağımlılıkları izole bir prefix'e kur ---
FROM python:3.12-slim AS build
WORKDIR /app
# requirements ÖNCE → kod değişince bu katman cache'te kalır
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- runtime stage: yalnız gerekli olan ---
FROM python:3.12-slim
WORKDIR /app
# build stage'den SADECE kurulmuş paketleri al — pip cache, derleyici GELMEZ
COPY --from=build /install /usr/local
COPY app.py .
ENV APP_PORT=8000
EXPOSE 8000
# non-root: imajda kullanıcı yaratmadan numeric UID ile çalış
USER 10001
CMD ["python", "app.py"]
