-- Add indexes for per-user notification pagination and read-notification retention cleanup.
-- Run once after creating in_app_notifications.

ALTER TABLE in_app_notifications
  ADD KEY idx_notifications_user_id_id (user_id, id),
  ADD KEY idx_notifications_read_at_id (read_at, id);
