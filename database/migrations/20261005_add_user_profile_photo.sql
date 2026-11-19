ALTER TABLE `users`
  ADD COLUMN `profile_photo` varchar(255) DEFAULT NULL
  AFTER `organization_id`;
