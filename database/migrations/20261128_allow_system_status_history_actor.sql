-- Allow automated status changes to be recorded without impersonating a user.
ALTER TABLE `concern_status_history`
  MODIFY COLUMN `changed_by` int(10) UNSIGNED DEFAULT NULL;