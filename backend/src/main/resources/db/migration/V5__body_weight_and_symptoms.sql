ALTER TABLE body_records ADD COLUMN weight DECIMAL(5,1) NULL AFTER temperature;

CREATE TABLE symptom_events (
  id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  space_id CHAR(36) NOT NULL,
  tag VARCHAR(40) NOT NULL,
  happened_at DATETIME(3) NOT NULL,
  note TEXT,
  created_by CHAR(36),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_symptom_events_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_symptom_events_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX symptom_events_space_time_idx ON symptom_events(space_id, happened_at DESC);
