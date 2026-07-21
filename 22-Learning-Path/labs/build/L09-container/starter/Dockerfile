# Dockerfile — SEN doldur. Multi-stage olacak. (solution/ önce KENDİN dene.)
#
# Hedef:
#   1) build stage: bağımlılıkları --prefix=/install ile kur
#   2) runtime stage: python:3.12-slim üstüne SADECE /install + app.py kopyala
#   3) non-root çalıştır (USER 10001)
#   4) requirements önce, kod sonra kopyalansın → cache dostu

# --- build stage ---
FROM python:3.12-slim AS build
WORKDIR /app
# TODO: requirements.txt'i kopyala ve pip install --prefix=/install ... çalıştır

# --- runtime stage ---
FROM python:3.12-slim
WORKDIR /app
# TODO: COPY --from=build /install /usr/local
# TODO: COPY app.py .
ENV APP_PORT=8000
EXPOSE 8000
# TODO: USER 10001
CMD ["python", "app.py"]
