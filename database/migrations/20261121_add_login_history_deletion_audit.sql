-- Audit summary for manual login-history deletions.
CREATE TABLE IF NOT EXISTS login_history_deletion_audit (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  deletion_mode VARCHAR(20) NOT NULL,
  deleted_count INT UNSIGNED NOT NULL DEFAULT 0,
  date_from DATETIME NULL,
  date_to DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_login_history_audit_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
