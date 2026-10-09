ALTER TABLE `concerns`
  ADD COLUMN `deleted_at` datetime DEFAULT NULL AFTER `closed_at`,
  ADD COLUMN `deleted_by` int(10) UNSIGNED DEFAULT NULL AFTER `deleted_at`,
  ADD KEY `idx_concerns_deleted_at` (`deleted_at`),
  ADD CONSTRAINT `fk_concerns_deleted_by`
    FOREIGN KEY (`deleted_by`) REFERENCES `users` (`id`)
    ON DELETE SET NULL ON UPDATE CASCADE;
