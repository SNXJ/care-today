CREATE TABLE users (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  phone VARCHAR(32),
  email VARCHAR(255),
  nickname VARCHAR(80) NOT NULL,
  password_hash TEXT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  last_login_at DATETIME(3),
  deleted_at DATETIME(3),
  active_phone VARCHAR(32) GENERATED ALWAYS AS (IF(deleted_at IS NULL, phone, NULL)) STORED,
  active_email VARCHAR(255) GENERATED ALWAYS AS (IF(deleted_at IS NULL, email, NULL)) STORED,
  CONSTRAINT users_phone_or_email CHECK (phone IS NOT NULL OR email IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE UNIQUE INDEX users_phone_unique ON users (active_phone);
CREATE UNIQUE INDEX users_email_unique ON users (active_email);

CREATE TABLE care_spaces (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(120) NOT NULL,
  patient_user_id CHAR(36) NOT NULL,
  patient_nickname VARCHAR(80) NOT NULL,
  description TEXT,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_care_spaces_patient_user FOREIGN KEY (patient_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE space_members (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  user_id CHAR(36),
  nickname VARCHAR(80) NOT NULL,
  role ENUM('patient_admin', 'family', 'friend', 'readonly') NOT NULL,
  status ENUM('pending', 'active', 'removed') NOT NULL DEFAULT 'pending',
  joined_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  removed_at DATETIME(3),
  active_user_id CHAR(36) GENERATED ALWAYS AS (IF(status <> 'removed', user_id, NULL)) STORED,
  CONSTRAINT fk_space_members_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_space_members_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX space_members_space_id_idx ON space_members(space_id);
CREATE INDEX space_members_user_idx ON space_members(user_id);
CREATE UNIQUE INDEX space_members_active_user_unique ON space_members(space_id, active_user_id);

CREATE TABLE events (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  scheduled_at DATETIME(3) NOT NULL,
  location VARCHAR(180),
  note TEXT,
  needs_companion BOOLEAN NOT NULL DEFAULT false,
  created_by CHAR(36),
  companion_member_id CHAR(36),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_events_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_events_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_events_companion FOREIGN KEY (companion_member_id) REFERENCES space_members(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX events_space_scheduled_idx ON events(space_id, scheduled_at);

CREATE TABLE body_records (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  user_id CHAR(36),
  pain_score SMALLINT NOT NULL CHECK (pain_score BETWEEN 0 AND 10),
  fatigue_score SMALLINT NOT NULL CHECK (fatigue_score BETWEEN 0 AND 10),
  sleep_score SMALLINT NOT NULL CHECK (sleep_score BETWEEN 0 AND 10),
  mood_score SMALLINT NOT NULL CHECK (mood_score BETWEEN 0 AND 10),
  appetite_score SMALLINT NOT NULL CHECK (appetite_score BETWEEN 0 AND 10),
  temperature DECIMAL(4, 1) NOT NULL CHECK (temperature BETWEEN 34 AND 42),
  note TEXT,
  record_date DATE NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_body_records_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_body_records_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX body_records_space_date_idx ON body_records(space_id, record_date DESC);

CREATE TABLE doctor_questions (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  question TEXT NOT NULL,
  asked BOOLEAN NOT NULL DEFAULT false,
  important BOOLEAN NOT NULL DEFAULT false,
  doctor_answer TEXT,
  created_by CHAR(36),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_doctor_questions_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_doctor_questions_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX doctor_questions_space_idx ON doctor_questions(space_id, created_at DESC);

CREATE TABLE help_tasks (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  type VARCHAR(40) NOT NULL,
  description TEXT,
  scheduled_at DATETIME(3),
  created_by CHAR(36),
  claimed_by CHAR(36),
  status ENUM('pending', 'claimed', 'done', 'cancelled') NOT NULL DEFAULT 'pending',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_help_tasks_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_help_tasks_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_help_tasks_claimed_by FOREIGN KEY (claimed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX help_tasks_space_status_idx ON help_tasks(space_id, status, scheduled_at);

CREATE TABLE messages (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  user_id CHAR(36),
  text TEXT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_messages_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX messages_space_created_idx ON messages(space_id, created_at DESC);

CREATE TABLE notes (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  type VARCHAR(40) NOT NULL,
  content TEXT,
  visibility ENUM('patient_admin', 'members') NOT NULL DEFAULT 'patient_admin',
  created_by CHAR(36),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_notes_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_notes_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX notes_space_visibility_idx ON notes(space_id, visibility, created_at DESC);

CREATE TABLE audit_logs (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36),
  user_id CHAR(36),
  action VARCHAR(120) NOT NULL,
  target_type VARCHAR(80) NOT NULL,
  target_id CHAR(36),
  ip_address VARCHAR(64),
  user_agent TEXT,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_audit_logs_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE SET NULL,
  CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX audit_logs_space_created_idx ON audit_logs(space_id, created_at DESC);
CREATE INDEX audit_logs_user_created_idx ON audit_logs(user_id, created_at DESC);
