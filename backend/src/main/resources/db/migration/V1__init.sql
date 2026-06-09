CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE member_role AS ENUM ('patient_admin', 'family', 'friend', 'readonly');
CREATE TYPE member_status AS ENUM ('pending', 'active', 'removed');
CREATE TYPE help_task_status AS ENUM ('pending', 'claimed', 'done', 'cancelled');
CREATE TYPE note_visibility AS ENUM ('patient_admin', 'members');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(32),
  email VARCHAR(255),
  nickname VARCHAR(80) NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  CONSTRAINT users_phone_or_email CHECK (phone IS NOT NULL OR email IS NOT NULL)
);

CREATE UNIQUE INDEX users_phone_unique ON users (phone) WHERE phone IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX users_email_unique ON users (email) WHERE email IS NOT NULL AND deleted_at IS NULL;

CREATE TABLE care_spaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) NOT NULL,
  patient_user_id UUID NOT NULL REFERENCES users(id),
  patient_nickname VARCHAR(80) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE space_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES care_spaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  nickname VARCHAR(80) NOT NULL,
  role member_role NOT NULL,
  status member_status NOT NULL DEFAULT 'pending',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  removed_at TIMESTAMPTZ
);

CREATE INDEX space_members_space_id_idx ON space_members(space_id);
CREATE UNIQUE INDEX space_members_active_user_unique ON space_members(space_id, user_id)
  WHERE user_id IS NOT NULL AND status <> 'removed';

CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES care_spaces(id) ON DELETE CASCADE,
  title VARCHAR(160) NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  location VARCHAR(180),
  note TEXT,
  needs_companion BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES users(id),
  companion_member_id UUID REFERENCES space_members(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX events_space_scheduled_idx ON events(space_id, scheduled_at);

CREATE TABLE body_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES care_spaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  pain_score SMALLINT NOT NULL CHECK (pain_score BETWEEN 0 AND 10),
  fatigue_score SMALLINT NOT NULL CHECK (fatigue_score BETWEEN 0 AND 10),
  sleep_score SMALLINT NOT NULL CHECK (sleep_score BETWEEN 0 AND 10),
  mood_score SMALLINT NOT NULL CHECK (mood_score BETWEEN 0 AND 10),
  appetite_score SMALLINT NOT NULL CHECK (appetite_score BETWEEN 0 AND 10),
  temperature NUMERIC(4, 1) NOT NULL CHECK (temperature BETWEEN 34 AND 42),
  note TEXT,
  record_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX body_records_space_date_idx ON body_records(space_id, record_date DESC);

CREATE TABLE doctor_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES care_spaces(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  asked BOOLEAN NOT NULL DEFAULT false,
  important BOOLEAN NOT NULL DEFAULT false,
  doctor_answer TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX doctor_questions_space_idx ON doctor_questions(space_id, created_at DESC);

CREATE TABLE help_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES care_spaces(id) ON DELETE CASCADE,
  title VARCHAR(160) NOT NULL,
  type VARCHAR(40) NOT NULL,
  description TEXT,
  scheduled_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  claimed_by UUID REFERENCES users(id),
  status help_task_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX help_tasks_space_status_idx ON help_tasks(space_id, status, scheduled_at);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES care_spaces(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX messages_space_created_idx ON messages(space_id, created_at DESC);

CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID NOT NULL REFERENCES care_spaces(id) ON DELETE CASCADE,
  title VARCHAR(160) NOT NULL,
  type VARCHAR(40) NOT NULL,
  content TEXT,
  visibility note_visibility NOT NULL DEFAULT 'patient_admin',
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX notes_space_visibility_idx ON notes(space_id, visibility, created_at DESC);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  space_id UUID REFERENCES care_spaces(id) ON DELETE SET NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(120) NOT NULL,
  target_type VARCHAR(80) NOT NULL,
  target_id UUID,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX audit_logs_space_created_idx ON audit_logs(space_id, created_at DESC);
CREATE INDEX audit_logs_user_created_idx ON audit_logs(user_id, created_at DESC);
