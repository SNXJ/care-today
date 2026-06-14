SET @target_space_id := (
  SELECT s.id
  FROM care_spaces s
  JOIN users u ON u.id = s.patient_user_id
  WHERE s.deleted_at IS NULL
    AND (s.patient_nickname = '患者甲' OR u.nickname = '患者甲')
  ORDER BY s.created_at ASC
  LIMIT 1
);

SET @family_member_user_id := (
  SELECT id
  FROM users
  WHERE nickname = 'family_member' AND deleted_at IS NULL
  ORDER BY created_at ASC
  LIMIT 1
);

SET @family_member_membership_exists := (
  SELECT COUNT(*)
  FROM space_members
  WHERE space_id = @target_space_id
    AND user_id = @family_member_user_id
    AND status <> 'removed'
);

CREATE TEMPORARY TABLE merge_family_member_source_spaces (
  id CHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci PRIMARY KEY
);

INSERT INTO merge_family_member_source_spaces (id)
SELECT DISTINCT s.id
FROM care_spaces s
LEFT JOIN space_members m ON m.space_id = s.id
WHERE @target_space_id IS NOT NULL
  AND s.deleted_at IS NULL
  AND s.id <> @target_space_id
  AND (
    s.patient_nickname = 'family_member'
    OR s.patient_user_id = @family_member_user_id
    OR (m.user_id = @family_member_user_id AND m.status <> 'removed')
  );

UPDATE care_spaces
SET patient_nickname = '患者甲'
WHERE id = @target_space_id
  AND @target_space_id IS NOT NULL;

INSERT INTO space_members (id, space_id, user_id, nickname, role, status, joined_at)
SELECT UUID(), @target_space_id, @family_member_user_id, 'family_member', 'family', 'active', CURRENT_TIMESTAMP(3)
WHERE @target_space_id IS NOT NULL
  AND @family_member_user_id IS NOT NULL
  AND COALESCE(@family_member_membership_exists, 0) = 0;

UPDATE events
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE body_records
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE doctor_questions
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE help_tasks
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE messages
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE notes
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE care_notices
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE symptom_events
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE audit_logs
SET space_id = @target_space_id
WHERE @target_space_id IS NOT NULL
  AND space_id IN (SELECT id FROM merge_family_member_source_spaces);

UPDATE care_spaces
SET deleted_at = CURRENT_TIMESTAMP(3)
WHERE @target_space_id IS NOT NULL
  AND id IN (SELECT id FROM merge_family_member_source_spaces);

DROP TEMPORARY TABLE merge_family_member_source_spaces;
