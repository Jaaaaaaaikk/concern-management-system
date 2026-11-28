-- Each concern category now has one receiving organization.
-- Categories with exactly one legacy organization are migrated automatically.
-- Categories with multiple or no legacy destinations remain NULL and must be
-- assigned explicitly by a Superadmin in Manage Concern Categories before use.

ALTER TABLE `concern_types`
  ADD COLUMN `assigned_organization_id` int(10) unsigned DEFAULT NULL AFTER `description`,
  ADD KEY `idx_concern_types_assigned_organization` (`assigned_organization_id`),
  ADD CONSTRAINT `fk_concern_types_assigned_organization`
    FOREIGN KEY (`assigned_organization_id`) REFERENCES `organizations` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE;

UPDATE `concern_types` category
INNER JOIN (
  SELECT
    `concern_type_id`,
    MIN(`organization_id`) AS `organization_id`
  FROM `organization_concern_types`
  GROUP BY `concern_type_id`
  HAVING COUNT(DISTINCT `organization_id`) = 1
) legacy_assignment
  ON legacy_assignment.`concern_type_id` = category.`id`
SET category.`assigned_organization_id` = legacy_assignment.`organization_id`;
