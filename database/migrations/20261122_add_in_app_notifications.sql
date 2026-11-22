-- In-app notifications for concern activity and system administration changes.
-- Run once against concern_management before deploying the notification feature.

CREATE TABLE IF NOT EXISTS in_app_notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT(10) UNSIGNED NOT NULL,
  event_type VARCHAR(40) NOT NULL,
  concern_id BIGINT(20) UNSIGNED NULL,
  actor_user_id INT(10) UNSIGNED NULL,
  title VARCHAR(120) NOT NULL,
  message VARCHAR(500) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_in_app_notifications_user_created (user_id, created_at),
  KEY idx_in_app_notifications_user_read (user_id, read_at),
  CONSTRAINT fk_in_app_notifications_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_in_app_notifications_concern
    FOREIGN KEY (concern_id) REFERENCES concerns (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_in_app_notifications_actor
    FOREIGN KEY (actor_user_id) REFERENCES users (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
