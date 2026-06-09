#!/usr/bin/env sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-./backups}"
CONTAINER="${MYSQL_CONTAINER:-care-today-mysql}"
DATABASE="${MYSQL_DATABASE:-care_today}"
USER="${MYSQL_USER:-care_today}"
PASSWORD="${MYSQL_PASSWORD:-care_today_password}"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"
docker exec -e MYSQL_PWD="$PASSWORD" "$CONTAINER" mysqldump -u "$USER" "$DATABASE" > "$BACKUP_DIR/care_today-$STAMP.sql"
echo "Backup written to $BACKUP_DIR/care_today-$STAMP.sql"
