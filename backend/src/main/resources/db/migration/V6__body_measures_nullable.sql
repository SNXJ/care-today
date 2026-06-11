ALTER TABLE body_records
  MODIFY pain_score SMALLINT NULL,
  MODIFY fatigue_score SMALLINT NULL,
  MODIFY sleep_score SMALLINT NULL,
  MODIFY mood_score SMALLINT NULL,
  MODIFY appetite_score SMALLINT NULL,
  MODIFY temperature DECIMAL(4,1) NULL;
