#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
NETWORK="${NETWORK:-care-today-net}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-care-today-mysql}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-care-today-backend}"
NGINX_CONTAINER="${NGINX_CONTAINER:-care-today-nginx}"
MYSQL_VOLUME="${MYSQL_VOLUME:-care_today_mysql}"
MYSQL_DATABASE="${MYSQL_DATABASE:-care_today}"
MYSQL_USER="${MYSQL_USER:-care_today}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-care_today_password}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-care_today_root_password}"
JWT_SECRET="${JWT_SECRET:-replace-with-a-long-random-secret}"

cd "$ROOT_DIR"
npm run build
(cd backend && mvn -q -DskipTests package)

docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK" >/dev/null

for container in "$NGINX_CONTAINER" "$BACKEND_CONTAINER" "$MYSQL_CONTAINER"; do
  if docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
    docker rm -f "$container" >/dev/null
  fi
done

docker volume inspect "$MYSQL_VOLUME" >/dev/null 2>&1 || docker volume create "$MYSQL_VOLUME" >/dev/null

docker run -d \
  --name "$MYSQL_CONTAINER" \
  --network "$NETWORK" \
  -v "$MYSQL_VOLUME":/var/lib/mysql \
  -e MYSQL_DATABASE="$MYSQL_DATABASE" \
  -e MYSQL_USER="$MYSQL_USER" \
  -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
  -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  mysql:8.4 >/dev/null

echo "Waiting for MySQL..."
for _ in $(seq 1 60); do
  if docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" "$MYSQL_CONTAINER" mysqladmin ping -uroot --silent >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker run -d \
  --name "$BACKEND_CONTAINER" \
  --network "$NETWORK" \
  --network-alias backend \
  -p 3000:3000 \
  -v "$ROOT_DIR/backend/target/care-today-backend-0.1.0.jar":/app/app.jar:ro \
  -e PORT=3000 \
  -e DATABASE_URL="jdbc:mysql://$MYSQL_CONTAINER:3306/$MYSQL_DATABASE?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai" \
  -e DATABASE_USER="$MYSQL_USER" \
  -e DATABASE_PASSWORD="$MYSQL_PASSWORD" \
  -e FLYWAY_ENABLED=true \
  -e JWT_SECRET="$JWT_SECRET" \
  eclipse-temurin:17-jre \
  java -jar /app/app.jar >/dev/null

echo "Waiting for backend..."
for _ in $(seq 1 60); do
  if docker run --rm --network "$NETWORK" curlimages/curl:8.10.1 -fsS "http://$BACKEND_CONTAINER:3000/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker run -d \
  --name "$NGINX_CONTAINER" \
  --network "$NETWORK" \
  -p 8080:80 \
  -v "$ROOT_DIR/dist":/usr/share/nginx/html:ro \
  -v "$ROOT_DIR/deploy/nginx.conf":/etc/nginx/conf.d/default.conf:ro \
  nginx:1.27-alpine >/dev/null

echo "CareToday deployed:"
echo "  Web: http://localhost:8080"
echo "  API: http://localhost:3000/api/health"
