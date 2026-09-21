-- 放宽日程标题/地点长度：用户习惯把较长的就诊说明写进标题，
-- 原 title VARCHAR(160) / location VARCHAR(180) 超长会触发 "Data too long" 500。
ALTER TABLE events MODIFY COLUMN title VARCHAR(500) NOT NULL;
ALTER TABLE events MODIFY COLUMN location VARCHAR(300);
