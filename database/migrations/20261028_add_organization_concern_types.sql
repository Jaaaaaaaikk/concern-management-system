-- Run once against concern_management before deploying the routing update.
-- Existing Admin Facilities organizations retain their current ability to
-- receive every active concern type; Superadmins can refine these mappings.

START TRANSACTION;

CREATE TABLE organization_concern_types (
  organization_id INT(10) UNSIGNED NOT NULL,
  concern_type_id INT(10) UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (organization_id, concern_type_id),
  KEY idx_organization_concern_types_type (concern_type_id),
  CONSTRAINT fk_organization_concern_types_organization
    FOREIGN KEY (organization_id) REFERENCES organizations (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_organization_concern_types_type
    FOREIGN KEY (concern_type_id) REFERENCES concern_types (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO organization_concern_types (organization_id, concern_type_id)
SELECT organizations.id, concern_types.id
FROM organizations
CROSS JOIN concern_types
WHERE organizations.organization_type = 'admin_facilities'
  AND organizations.deleted_at IS NULL
  AND concern_types.status = 'active';

COMMIT;