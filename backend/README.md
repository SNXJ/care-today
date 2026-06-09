# CareToday Backend

NestJS API scaffold for CareToday.

## Current Scope

This backend currently provides REST endpoint shapes with in-memory storage. It is intended to lock down the first API contract before wiring a real database and authentication layer.

Implemented endpoint groups:

- `GET /api/health`
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

```bash
cd backend
npm install
npm run dev
```

API base URL:

```text
http://localhost:3000/api
```

## Database

PostgreSQL schema draft:

```text
backend/database/schema.sql
```

The first real persistence pass should add:

- connection pooling
- migrations
- password hashing
- JWT authentication
- space membership authorization guards
- audit log writes for sensitive operations

## Medical Boundary

The backend must never return diagnosis, treatment suggestions, medication judgments, or risk predictions. Body records are only for review and appointment preparation.
