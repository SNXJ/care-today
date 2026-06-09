#!/usr/bin/env sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-./backups}"
CONTAINER="${POSTGRES_CONTAINER:-care-today-postgres}"
DATABASE="${POSTGRES_DB:-care_today}"
USER="${POSTGRES_USER:-care_today}"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"
docker exec "$CONTAINER" pg_dump -U "$USER" "$DATABASE" > "$BACKUP_DIR/care_today-$STAMP.sql"
echo "Backup written to $BACKUP_DIR/care_today-$STAMP.sql"
