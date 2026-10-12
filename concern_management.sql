-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 12, 2026 at 03:37 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `concern_management`
--

-- --------------------------------------------------------

--
-- Table structure for table `concerns`
--

CREATE TABLE `concerns` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `concern_number` varchar(30) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `concern_type_id` int(10) UNSIGNED DEFAULT NULL,
  `created_by` int(10) UNSIGNED NOT NULL,
  `assigned_organization_id` int(10) UNSIGNED DEFAULT NULL,
  `status` enum('pending','in_progress','on_hold','resolved','closed') NOT NULL DEFAULT 'pending',
  `priority` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `target_commitment_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `resolved_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `concern_attachments`
--

CREATE TABLE `concern_attachments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `concern_id` bigint(20) UNSIGNED NOT NULL,
  `comment_id` bigint(20) UNSIGNED DEFAULT NULL,
  `uploaded_by` int(10) UNSIGNED NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `file_size` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `edited_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `concern_comments`
--

CREATE TABLE `concern_comments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `concern_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `comment` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `concern_status_attachments`
--

CREATE TABLE `concern_status_attachments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `status_history_id` bigint(20) UNSIGNED NOT NULL,
  `concern_id` bigint(20) UNSIGNED NOT NULL,
  `uploaded_by` int(10) UNSIGNED NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(100) NOT NULL,
  `file_size` bigint(20) UNSIGNED NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `concern_status_history`
--

CREATE TABLE `concern_status_history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `concern_id` bigint(20) UNSIGNED NOT NULL,
  `changed_by` int(10) UNSIGNED NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `concern_types`
--

CREATE TABLE `concern_types` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `concern_types`
--

INSERT INTO `concern_types` (`id`, `name`, `description`, `status`, `created_at`, `updated_at`) VALUES
(1, 'IT / Technical', 'Computer, software, hardware, network, and technical concerns', 'active', '2026-10-01 21:22:29', '2026-10-01 21:22:29'),
(2, 'Facilities', 'Building, room, equipment, and facility-related concerns', 'active', '2026-10-01 21:22:29', '2026-10-01 21:22:29'),
(3, 'Maintenance', 'Repair and maintenance concerns', 'active', '2026-10-01 21:22:29', '2026-10-01 21:22:29'),
(4, 'Security', 'Security and safety-related concerns', 'active', '2026-10-01 21:22:29', '2026-10-01 21:22:29'),
(5, 'Other', 'Other concerns not covered by the available categories', 'active', '2026-10-01 21:22:29', '2026-10-01 21:22:29');

-- --------------------------------------------------------

--
-- Table structure for table `organizations`
--

CREATE TABLE `organizations` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `organization_type` enum('bpo','tenant','admin_facilities') NOT NULL DEFAULT 'tenant',
  `description` text DEFAULT NULL,
  `contact_email` varchar(150) DEFAULT NULL,
  `contact_number` varchar(50) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `organizations`
--

INSERT INTO `organizations` (`id`, `name`, `organization_type`, `description`, `contact_email`, `contact_number`, `address`, `status`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'IT Department', 'admin_facilities', 'Information Technology Department', NULL, NULL, 'UG Alfresco Building A', 'active', '2026-10-01 21:22:29', '2026-10-04 22:36:35', NULL),
(2, 'VXI', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale Building A', 'active', '2026-10-02 11:44:39', '2026-10-02 11:44:39', NULL),
(3, 'Engineering Department', 'admin_facilities', 'Felcris Centrale Engineering Team', NULL, NULL, 'Felcris Centrale UG Parking', 'active', '2026-10-02 14:09:36', '2026-10-04 22:37:00', NULL),
(4, 'Optum', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:19:29', '2026-10-09 15:19:56', NULL),
(5, 'TelePerformance', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:20:30', '2026-10-09 15:20:30', NULL),
(6, 'IBEX', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:20:55', '2026-10-09 15:20:55', NULL),
(7, 'Regus', 'tenant', NULL, NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:21:43', '2026-10-09 15:21:43', NULL),
(8, 'Intellicare', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:22:16', '2026-10-11 09:29:01', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `roles`
--

INSERT INTO `roles` (`id`, `name`, `description`, `created_at`, `updated_at`) VALUES
(1, 'superadmin', 'Full system access and user management', '2026-10-01 21:22:29', '2026-10-01 21:22:29'),
(2, 'admin', 'Organization or department administrator', '2026-10-01 21:22:29', '2026-10-01 21:22:29'),
(3, 'user', 'Can create and manage own concerns', '2026-10-01 21:22:29', '2026-10-01 21:22:29');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `middle_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) NOT NULL,
  `role_id` int(10) UNSIGNED NOT NULL,
  `organization_id` int(10) UNSIGNED DEFAULT NULL,
  `profile_photo` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','suspended') NOT NULL DEFAULT 'active',
  `last_login_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password_hash`, `first_name`, `middle_name`, `last_name`, `role_id`, `organization_id`, `profile_photo`, `status`, `last_login_at`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'superadmin', '$2b$12$7Q2BZNGJ8VG8/aX288L7zextU/UWOthz0MWQarPSPUik6UwaYlnXK', 'System', NULL, 'Administrator', 1, NULL, '/uploads/users/0f5206e8-6c0d-46cc-9b3f-a59d4ee8e31c.png', 'active', '2026-10-12 09:34:03', '2026-10-01 21:22:29', '2026-10-12 09:34:03', NULL),
(2, 'anna', '$2b$12$WoKBHfx6YUm5VGwaKVn5V./JI6sx8Iv6czZ/qi8x0ww82a3tfirNy', 'Anna', 'Dela', 'Fuente', 2, 1, NULL, 'active', '2026-10-04 22:18:00', '2026-10-02 11:04:52', '2026-10-04 22:18:00', NULL),
(3, 'juan123', '$2b$12$g6jwacvi2I/Mjuxznjqmi.b56UDzfZp3skg6/O6BZtydNNIGeelJq', 'juan', 'dela', 'cruz', 2, 3, NULL, 'active', '2026-10-05 16:18:53', '2026-10-03 21:36:12', '2026-10-05 16:18:53', NULL),
(4, 'john', '$2b$12$Sm6WMLnnsr3J.0vG8rWFv.kC71V5KawFXzQ7L11GILFFxDeBuTzNm', 'john', 'doe', 'doe', 2, 2, NULL, 'active', '2026-10-09 17:41:20', '2026-10-03 21:46:59', '2026-10-09 17:41:20', NULL),
(5, 'rose', '$2b$12$848WcWXTx.bI9TPSuqDizevBId4ZBemi3u7ASO//MKsAmNyGPolw2', 'rosemarie', NULL, 'dimagiba', 2, 3, NULL, 'active', '2026-10-12 09:36:43', '2026-10-03 21:48:33', '2026-10-12 09:36:43', NULL),
(6, 'sample', '$2b$12$p7PWE8B6Awwdjx5zob.sRuv/xW6Yly/ErTIouWyUoZKO/rK131LaC', 'sample', NULL, 'user', 3, 3, NULL, 'active', '2026-10-09 15:27:30', '2026-10-04 22:13:40', '2026-10-09 15:27:30', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_sessions`
--

CREATE TABLE `user_sessions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `session_token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `revoked_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_sessions`
--

INSERT INTO `user_sessions` (`id`, `user_id`, `session_token_hash`, `expires_at`, `created_at`, `revoked_at`) VALUES
(1, 1, '8e1f72a7b824fe2f309e7effc1ced11449748f30f4b0e38e05f60439e1d07824', '2026-10-12 17:34:03', '2026-10-12 09:34:03', '2026-10-12 09:36:35'),
(2, 5, '76844da5417b7f53553ce972b0e7b66c4a21d0db5f6daf210032d2469c4de585', '2026-10-12 17:36:43', '2026-10-12 09:36:43', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `concerns`
--
ALTER TABLE `concerns`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `concern_number` (`concern_number`),
  ADD KEY `idx_concerns_created_by` (`created_by`),
  ADD KEY `idx_concerns_organization` (`assigned_organization_id`),
  ADD KEY `idx_concerns_status` (`status`),
  ADD KEY `idx_concerns_priority` (`priority`),
  ADD KEY `idx_concerns_type` (`concern_type_id`),
  ADD KEY `idx_concerns_created_at` (`created_at`),
  ADD KEY `idx_concerns_deleted_at` (`deleted_at`),
  ADD KEY `fk_concerns_deleted_by` (`deleted_by`);

--
-- Indexes for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_attachments_concern` (`concern_id`),
  ADD KEY `idx_attachments_user` (`uploaded_by`),
  ADD KEY `idx_attachments_comment` (`comment_id`);

--
-- Indexes for table `concern_comments`
--
ALTER TABLE `concern_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_comments_concern` (`concern_id`),
  ADD KEY `idx_comments_user` (`user_id`),
  ADD KEY `idx_comments_created_at` (`created_at`);

--
-- Indexes for table `concern_status_attachments`
--
ALTER TABLE `concern_status_attachments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_status_history_id` (`status_history_id`),
  ADD KEY `idx_concern_id` (`concern_id`),
  ADD KEY `idx_uploaded_by` (`uploaded_by`);

--
-- Indexes for table `concern_status_history`
--
ALTER TABLE `concern_status_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_status_history_concern` (`concern_id`),
  ADD KEY `idx_status_history_user` (`changed_by`),
  ADD KEY `idx_status_history_created_at` (`created_at`);

--
-- Indexes for table `concern_types`
--
ALTER TABLE `concern_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `organizations`
--
ALTER TABLE `organizations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_organization_name` (`name`),
  ADD KEY `idx_organization_status` (`status`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_users_role` (`role_id`),
  ADD KEY `idx_users_organization` (`organization_id`),
  ADD KEY `idx_users_status` (`status`),
  ADD KEY `idx_users_name` (`last_name`,`first_name`);

--
-- Indexes for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `session_token_hash` (`session_token_hash`),
  ADD KEY `idx_sessions_user` (`user_id`),
  ADD KEY `idx_sessions_expires` (`expires_at`),
  ADD KEY `idx_sessions_revoked` (`revoked_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `concerns`
--
ALTER TABLE `concerns`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `concern_comments`
--
ALTER TABLE `concern_comments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `concern_status_attachments`
--
ALTER TABLE `concern_status_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `concern_status_history`
--
ALTER TABLE `concern_status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `concern_types`
--
ALTER TABLE `concern_types`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `organizations`
--
ALTER TABLE `organizations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `concerns`
--
ALTER TABLE `concerns`
  ADD CONSTRAINT `fk_concerns_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_concerns_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_concerns_organization` FOREIGN KEY (`assigned_organization_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_concerns_type` FOREIGN KEY (`concern_type_id`) REFERENCES `concern_types` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  ADD CONSTRAINT `fk_attachments_comment` FOREIGN KEY (`comment_id`) REFERENCES `concern_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_attachments_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_attachments_user` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `concern_comments`
--
ALTER TABLE `concern_comments`
  ADD CONSTRAINT `fk_comments_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `concern_status_attachments`
--
ALTER TABLE `concern_status_attachments`
  ADD CONSTRAINT `fk_status_attachment_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_status_attachment_history` FOREIGN KEY (`status_history_id`) REFERENCES `concern_status_history` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `concern_status_history`
--
ALTER TABLE `concern_status_history`
  ADD CONSTRAINT `fk_status_history_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_status_history_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_organization` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD CONSTRAINT `fk_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
