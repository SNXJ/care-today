CREATE TABLE care_notices (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  content VARCHAR(200) NOT NULL,
  detail TEXT,
  important BOOLEAN NOT NULL DEFAULT false,
  starts_on DATE,
  ends_on DATE,
  status ENUM('active', 'archived') NOT NULL DEFAULT 'active',
  created_by CHAR(36),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_care_notices_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_care_notices_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX care_notices_space_status_idx ON care_notices(space_id, status, created_at DESC);
