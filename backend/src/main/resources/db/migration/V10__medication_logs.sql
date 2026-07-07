CREATE TABLE medication_logs (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  name VARCHAR(80) NOT NULL,
  dosage VARCHAR(60),
  taken_at DATETIME(3) NOT NULL,
  note TEXT,
  created_by CHAR(36),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_medication_logs_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_medication_logs_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX medication_logs_space_time_idx ON medication_logs(space_id, taken_at DESC);
