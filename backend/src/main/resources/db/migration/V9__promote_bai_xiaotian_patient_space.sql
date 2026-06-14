SET @bai_user_id := (
  SELECT id
  FROM users
  WHERE nickname = '白小天' AND deleted_at IS NULL
  ORDER BY created_at ASC
  LIMIT 1
);

SET @target_space_id := (
  SELECT s.id
  FROM care_spaces s
  JOIN space_members m ON m.space_id = s.id
  WHERE @bai_user_id IS NOT NULL
    AND s.deleted_at IS NULL
    AND m.user_id = @bai_user_id
    AND m.status <> 'removed'
  ORDER BY s.created_at ASC
  LIMIT 1
);

SET @target_space_id := COALESCE(@target_space_id, (
  SELECT id
  FROM care_spaces
  WHERE @bai_user_id IS NOT NULL
    AND deleted_at IS NULL
    AND patient_nickname = 'shing'
  ORDER BY created_at ASC
  LIMIT 1
));

CREATE TEMPORARY TABLE merge_shing_source_spaces_v9 (
  id CHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci PRIMARY KEY
);

INSERT INTO merge_shing_source_spaces_v9 (id)
SELECT DISTINCT s.id
FROM care_spaces s
LEFT JOIN users patient ON patient.id = s.patient_user_id
LEFT JOIN space_members m ON m.space_id = s.id
LEFT JOIN users member_user ON member_user.id = m.user_id
WHERE @target_space_id IS NOT NULL
  AND s.deleted_at IS NULL
  AND s.id <> @target_space_id
  AND (
    s.patient_nickname = 'shing'
    OR patient.nickname = 'shing'
    OR (member_user.nickname = 'shing' AND m.status <> 'removed')
  );

UPDATE care_spaces
SET patient_user_id = @bai_user_id,
    patient_nickname = '白小天'
WHERE @target_space_id IS NOT NULL
  AND @bai_user_id IS NOT NULL
  AND id = @target_space_id;

UPDATE space_members
SET role = 'patient_admin',
    nickname = '白小天',
    status = 'active'
WHERE @target_space_id IS NOT NULL
  AND user_id = @bai_user_id
  AND space_id = @target_space_id
  AND status <> 'removed';

INSERT IGNORE INTO space_members (id, space_id, user_id, nickname, role, status, joined_at)
SELECT UUID(), @target_space_id, u.id, u.nickname, 'family', 'active', CURRENT_TIMESTAMP(3)
FROM users u
WHERE @target_space_id IS NOT NULL
  AND u.nickname = 'shing'
  AND u.deleted_at IS NULL;

UPDATE space_members m
JOIN users u ON u.id = m.user_id
SET m.role = 'family',
    m.nickname = u.nickname,
    m.status = 'active'
WHERE @target_space_id IS NOT NULL
  AND m.space_id = @target_space_id
  AND u.nickname = 'shing'
  AND m.status <> 'removed';

INSERT IGNORE INTO space_members (id, space_id, user_id, nickname, role, status, joined_at)
SELECT UUID(),
       @target_space_id,
       m.user_id,
       m.nickname,
       CASE WHEN m.role = 'patient_admin' THEN 'family' ELSE m.role END,
       'active',
       CURRENT_TIMESTAMP(3)
FROM space_members m
WHERE @target_space_id IS NOT NULL
  AND m.space_id IN (SELECT id FROM merge_shing_source_spaces_v9)
  AND m.status <> 'removed'
  AND m.user_id IS NOT NULL;

UPDATE events
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE body_records
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE doctor_questions
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE help_tasks
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE messages
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE notes
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE care_notices
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE symptom_events
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE audit_logs
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_shing_source_spaces_v9);

UPDATE care_spaces
SET deleted_at = CURRENT_TIMESTAMP(3)
WHERE @target_space_id IS NOT NULL
  AND id IN (SELECT id FROM merge_shing_source_spaces_v9);

DROP TEMPORARY TABLE merge_shing_source_spaces_v9;
