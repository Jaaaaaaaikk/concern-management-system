-- Supports the scheduled six-month purge of old session history.
ALTER TABLE user_sessions
  ADD KEY idx_user_sessions_created_at (created_at);
