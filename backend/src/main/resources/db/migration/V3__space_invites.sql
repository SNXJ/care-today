CREATE TABLE space_invites (
  token CHAR(36) PRIMARY KEY,
  space_id CHAR(36) NOT NULL,
  invited_by CHAR(36) NOT NULL,
  nickname VARCHAR(80) NOT NULL,
  role ENUM('family', 'friend', 'readonly') NOT NULL DEFAULT 'friend',
  accepted_by CHAR(36),
  accepted_at DATETIME(3),
  revoked_at DATETIME(3),
  expires_at DATETIME(3) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_space_invites_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_space_invites_invited_by FOREIGN KEY (invited_by) REFERENCES users(id),
  CONSTRAINT fk_space_invites_accepted_by FOREIGN KEY (accepted_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX space_invites_space_created_idx ON space_invites(space_id, created_at DESC);
