# CareToday Backend

Spring Boot API scaffold for CareToday.

## Current Scope

This backend provides the first Spring Boot API implementation for CareToday. It uses JWT authentication, BCrypt password hashing, Flyway migrations, PostgreSQL persistence, and space membership checks.

Implemented endpoint groups:

- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET/POST /api/spaces`
- `GET /api/spaces/:spaceId`
- `POST /api/spaces/:spaceId/members`
- `GET/POST /api/spaces/:spaceId/events`
- `GET/POST /api/spaces/:spaceId/body-records`
- `GET/POST/PATCH /api/spaces/:spaceId/doctor-questions`
- `GET/POST /api/spaces/:spaceId/help-tasks`
- `PATCH /api/spaces/:spaceId/help-tasks/:taskId/claim`
- `GET/POST /api/spaces/:spaceId/messages`
- `GET/POST /api/spaces/:spaceId/notes`

## Run Locally

The API requires PostgreSQL. Create a database/user matching `.env.example`, then enable Flyway:

```bash
export DATABASE_URL=jdbc:postgresql://localhost:5432/care_today
export DATABASE_USER=care_today
export DATABASE_PASSWORD=care_today_password
export FLYWAY_ENABLED=true
export JWT_SECRET=replace-with-a-long-random-secret
```

```bash
cd backend
mvn spring-boot:run
```

API base URL:

```text
http://localhost:3000/api
```

## Build

```bash
cd backend
mvn clean package
java -jar target/care-today-backend-0.1.0.jar
```

## Database

PostgreSQL schema and Flyway migration:

```text
backend/database/schema.sql
backend/src/main/resources/db/migration/V1__init.sql
```

Persisted tables:

- `users`
- `care_spaces`
- `space_members`
- `events`
- `body_records`
- `doctor_questions`
- `help_tasks`
- `messages`
- `notes`
- `audit_logs`

Every `/api/spaces/:spaceId/**` endpoint requires the caller to be an active member of that space. Member invitation requires `PATIENT_ADMIN`.

## Auth

Register:

```http
POST /api/auth/register
```

Login:

```http
POST /api/auth/login
```

Authenticated requests must include:

```text
Authorization: Bearer <token>
```

## Remaining Backend Work

- member join/accept flow
- edit/delete endpoints
- account deletion and space exit
- request-level audit metadata such as IP and user agent
- automated API tests

## Medical Boundary

The backend must never return diagnosis, treatment suggestions, medication judgments, or risk predictions. Body records are only for review and appointment preparation.
