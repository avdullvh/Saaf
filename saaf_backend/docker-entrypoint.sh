#!/usr/bin/env sh
set -e

echo "Waiting for Postgres at ${DB_HOST:-db}:${DB_PORT:-5432}..."
python - <<'PY'
import os, sys, time
import psycopg2

host = os.getenv("DB_HOST", "db")
port = int(os.getenv("DB_PORT", "5432"))
user = os.getenv("DB_USER", "postgres")
password = os.getenv("DB_PASSWORD", "")
name = os.getenv("DB_NAME", "saaf_db")

deadline = time.time() + 60
while True:
    try:
        psycopg2.connect(host=host, port=port, user=user, password=password, dbname=name).close()
        break
    except Exception as e:
        if time.time() > deadline:
            print("Postgres not ready:", repr(e), file=sys.stderr)
            sys.exit(1)
        time.sleep(1)
PY

echo "Applying migrations..."
python manage.py migrate --noinput

echo "Starting Django..."
exec python manage.py runserver 0.0.0.0:8000

