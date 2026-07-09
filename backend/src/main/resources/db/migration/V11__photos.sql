-- 图片附件：分享动态与复诊资料支持照片
CREATE TABLE uploaded_files (
  id CHAR(36) PRIMARY KEY,
  space_id CHAR(36) NOT NULL,
  uploader_id CHAR(36),
  content_type VARCHAR(80) NOT NULL,
  size_bytes INT NOT NULL,
  data MEDIUMBLOB NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  deleted_at DATETIME(3),
  CONSTRAINT fk_uploaded_files_space FOREIGN KEY (space_id) REFERENCES care_spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_uploaded_files_uploader FOREIGN KEY (uploader_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX uploaded_files_space_idx ON uploaded_files(space_id, created_at DESC);

-- photos 列：JSON 数组，存 uploaded_files.id 列表
ALTER TABLE messages ADD COLUMN photos TEXT NULL;
ALTER TABLE notes ADD COLUMN photos TEXT NULL;
