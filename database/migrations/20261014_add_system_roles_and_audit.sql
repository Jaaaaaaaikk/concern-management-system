-- Run once against concern_management before deploying the updated app.
-- Existing users and organizations retain NULL audit actors (legacy records).

START TRANSACTION;

UPDATE roles SET name = 'concern_handler', description = 'Handles assigned concerns and manages their status' WHERE name = 'admin';
UPDATE roles SET name = 'requestor', description = 'Creates concerns and participates in authorized conversations' WHERE name = 'user';

INSERT INTO roles (id, name, description)
VALUES
  (4, 'system_admin', 'Manages system-wide concerns, organizations, and user accounts; cannot manage superadmin accounts or revoke sessions'),
  (5, 'system_monitor', 'Views system-wide concerns and dashboards and may comment; cannot create concerns or change statuses')
ON DUPLICATE KEY UPDATE
  description = VALUES(description);

ALTER TABLE users
  ADD COLUMN created_by INT(10) UNSIGNED NULL AFTER deleted_at,
  ADD COLUMN updated_by INT(10) UNSIGNED NULL AFTER created_by,
  ADD KEY idx_users_created_by (created_by),
  ADD KEY idx_users_updated_by (updated_by),
  ADD CONSTRAINT fk_users_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT fk_users_updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE organizations
  ADD COLUMN created_by INT(10) UNSIGNED NULL AFTER deleted_at,
  ADD COLUMN updated_by INT(10) UNSIGNED NULL AFTER created_by,
  ADD KEY idx_organizations_created_by (created_by),
  ADD KEY idx_organizations_updated_by (updated_by),
  ADD CONSTRAINT fk_organizations_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT fk_organizations_updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL ON UPDATE CASCADE;

COMMIT;

-- Expected role mapping after migration:
-- 1 superadmin, 2 concern_handler, 3 requestor,
-- 4 system_admin, 5 system_monitor.
-- To update your existing account assignments, use e.g.:
-- UPDATE users SET role_id = 2 WHERE id = <admin_user_id>;
-- UPDATE users SET role_id = 3 WHERE id = <requestor_user_id>;
