ALTER TABLE `concerns`
  ADD COLUMN `target_resolution_date` date DEFAULT NULL
  AFTER `acknowledged_at`;
