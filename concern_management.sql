-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 02, 2026 at 09:06 AM
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
  `status` enum('pending','in_progress','on_hold','resolved','closed','cancelled') NOT NULL DEFAULT 'pending',
  `priority` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `resolved_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `concerns`
--

INSERT INTO `concerns` (`id`, `concern_number`, `title`, `description`, `concern_type_id`, `created_by`, `assigned_organization_id`, `status`, `priority`, `created_at`, `updated_at`, `resolved_at`, `closed_at`) VALUES
(1, 'CON-2026-00001', 'Pipe', 'The pipe installed was leaking', 3, 2, 1, 'pending', 'high', '2026-10-02 12:03:18', '2026-10-02 12:03:18', NULL, NULL),
(2, 'CON-2026-00002', 'broken wall', 'broken wall at 3rdF cr', 2, 2, 2, 'pending', 'high', '2026-10-02 14:09:56', '2026-10-02 14:09:56', NULL, NULL),
(3, 'CON-2026-00003', 'leaks', 'water leaks at 4th f cr male', 2, 2, 3, 'pending', 'urgent', '2026-10-02 14:11:35', '2026-10-02 14:11:35', NULL, NULL),
(4, 'CON-2026-00004', 'cracked tiles', 'Cracked tiles near UG Alfresco Entrance', 3, 2, 3, 'pending', 'urgent', '2026-10-02 14:29:50', '2026-10-02 14:29:50', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `concern_attachments`
--

CREATE TABLE `concern_attachments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `concern_id` bigint(20) UNSIGNED NOT NULL,
  `uploaded_by` int(10) UNSIGNED NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `file_size` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `concern_attachments`
--

INSERT INTO `concern_attachments` (`id`, `concern_id`, `uploaded_by`, `file_name`, `file_path`, `file_type`, `file_size`, `created_at`) VALUES
(1, 1, 2, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/concern-1-434b89f1d38028e4f9cba21056186315.jpg', 'image/jpeg', 29037, '2026-10-02 12:03:18');

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

--
-- Dumping data for table `concern_comments`
--

INSERT INTO `concern_comments` (`id`, `concern_id`, `user_id`, `comment`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'hello', '2026-10-02 13:21:22', '2026-10-02 13:21:22');

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

INSERT INTO `organizations` (`id`, `name`, `description`, `contact_email`, `contact_number`, `address`, `status`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'IT Department', 'Information Technology Department', NULL, NULL, NULL, 'active', '2026-10-01 21:22:29', '2026-10-01 21:22:29', NULL),
(2, 'VXI', 'BPO Company', NULL, NULL, 'Felcris Centrale Building A', 'active', '2026-10-02 11:44:39', '2026-10-02 11:44:39', NULL),
(3, 'Engineering Department', 'Felcris Centrale Engineering Team', NULL, NULL, 'Felcris Centrale UG Parking', 'active', '2026-10-02 14:09:36', '2026-10-02 14:09:36', NULL);

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
  `status` enum('active','inactive','suspended') NOT NULL DEFAULT 'active',
  `last_login_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password_hash`, `first_name`, `middle_name`, `last_name`, `role_id`, `organization_id`, `status`, `last_login_at`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'superadmin', '$2b$12$7Q2BZNGJ8VG8/aX288L7zextU/UWOthz0MWQarPSPUik6UwaYlnXK', 'System', NULL, 'Administrator', 1, NULL, 'active', '2026-10-02 14:27:32', '2026-10-01 21:22:29', '2026-10-02 14:27:32', NULL),
(2, 'Robert', '$2b$12$WoKBHfx6YUm5VGwaKVn5V./JI6sx8Iv6czZ/qi8x0ww82a3tfirNy', 'Robert', 'wilson', 'Reyes', 2, 1, 'active', '2026-10-02 14:27:40', '2026-10-02 11:04:52', '2026-10-02 14:27:40', NULL);

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
(1, 1, '19a9b3764d178fdebf70998060f42cc77b0cc94422293b418bba66cbf01be233', '2026-10-02 05:36:15', '2026-10-01 21:36:15', NULL),
(2, 1, '3a2bab48d5d85a8c25171465bc2885cf176a49aa1d671119d33d9f99fc9283ec', '2026-10-02 05:41:28', '2026-10-01 21:41:28', '2026-10-01 21:41:31'),
(3, 1, '9314c22a2b1116a89d8a8ffa509d46b1554c0879a1521caf4805592615f78dde', '2026-10-02 05:46:55', '2026-10-01 21:46:55', '2026-10-01 21:47:46'),
(4, 1, '47c9f3fb399be3917a1b3f1c426433a9162c37918c66009df023202e894ab98d', '2026-10-02 05:48:39', '2026-10-01 21:48:39', NULL),
(5, 1, '4954088256bbebb8cf0c8e10d11d9ce3cd8362122102c2b4b9e64ea3b1908912', '2026-10-02 05:49:23', '2026-10-01 21:49:23', NULL),
(6, 1, '7d513a27a89962370aa9bc5ca92161ddaca96778583b6d18ea045962f864de12', '2026-10-02 05:51:14', '2026-10-01 21:51:14', NULL),
(7, 1, '02c4ffdf20e8c15500e35b365c8b13dbaef5fa86e53692da1dd1333f84cc3d11', '2026-10-02 05:56:19', '2026-10-01 21:56:19', '2026-10-01 22:06:12'),
(8, 1, '897a0f49884393e22ec46be4d0b339e77a3b4e529fb103ec7b60cb0ae9d94bd2', '2026-10-02 06:06:37', '2026-10-01 22:06:37', '2026-10-01 23:00:52'),
(9, 1, 'fd7c2fc9e90b7bba3e924f6e08f56bf1d608b415753ecca1f54fe19f38e2df5e', '2026-10-02 07:00:56', '2026-10-01 23:00:56', '2026-10-01 23:29:08'),
(10, 1, '340a63f00783405be6640ddd1b809e642b73aff991c9bc3e912721d686164302', '2026-10-02 07:27:41', '2026-10-01 23:27:41', '2026-10-01 23:28:22'),
(11, 1, '90ae41700c4b45f203f41d6a9129edbd9eee13ccf527bea381d548c80bda9535', '2026-10-02 07:33:04', '2026-10-01 23:33:04', '2026-10-01 23:33:05'),
(12, 1, '6c1e39d74c0ca2d14c79cfa615027c33c5d28a606476d7b495e92c76983d9b13', '2026-10-02 14:03:18', '2026-10-02 06:03:18', NULL),
(13, 1, '5eb6570cd9845358f52c5d88a18477b9724069f85f7bcc82dbfefabedd4c5fd9', '2026-10-02 18:59:56', '2026-10-02 10:59:56', '2026-10-02 11:13:39'),
(14, 1, '6157648a8bb9b36653d6e7a23d022011afb8b22c61fb16a09749ec119100805a', '2026-10-02 19:01:47', '2026-10-02 11:01:47', '2026-10-02 11:04:59'),
(15, 2, 'cb2b53acc923ff8a10629694f14d53a00fb8b7d65f48679ea3a5f3442eee344a', '2026-10-02 19:05:07', '2026-10-02 11:05:07', NULL),
(16, 1, '3a0d746bbb9799758cd9333dabfd8592a226a75c51cd492395f2be04190f40ef', '2026-10-02 19:18:12', '2026-10-02 11:18:12', NULL),
(17, 1, 'd7b0073300db2e48114256853a399f516dfba537d35bd6fe28f54cf1b3be302f', '2026-10-02 19:18:15', '2026-10-02 11:18:15', NULL),
(18, 1, 'b31f96b5fb816d7da9c38e97c8c073f47f93de9798fb1529b96f949a64454264', '2026-10-02 19:19:30', '2026-10-02 11:19:30', '2026-10-02 11:45:30'),
(19, 2, 'b0112de6a88b30c6f3b81ac37939897cbf5b38a5111029eeb0a785d2e5090972', '2026-10-02 19:45:50', '2026-10-02 11:45:50', '2026-10-02 13:21:35'),
(20, 1, 'b90c7e5110bbc0e6c001f4593cdfee14d52579dc52cd4b22337d926a2972b1e8', '2026-10-02 21:21:41', '2026-10-02 13:21:41', '2026-10-02 13:22:56'),
(21, 2, '7101345ccb14f44f02098b94691fcc0938540357428deb241ed54f821860602c', '2026-10-02 21:23:02', '2026-10-02 13:23:02', '2026-10-02 13:27:43'),
(22, 2, 'dff28a5a8ae4a448567b1dc574a36fceb8fa8785b6bdd61482296fd286b4ea6a', '2026-10-02 21:25:40', '2026-10-02 13:25:40', NULL),
(23, 2, '30dc51e6973c543cccaeafa668d5ded92d92e791d1c7b93de5ed74e748db6b5f', '2026-10-02 21:26:36', '2026-10-02 13:26:36', '2026-10-02 13:26:56'),
(24, 2, 'c59558744c6f7a6e0d66a05bcf416cec5f81248fcfc7a8b477e8a80c2b90f56c', '2026-10-02 21:28:04', '2026-10-02 13:28:04', '2026-10-02 13:37:01'),
(25, 1, '68718f87daa31f9297012a54646877aa467019c34a9c550e8940719e1899af38', '2026-10-02 21:37:06', '2026-10-02 13:37:06', '2026-10-02 13:47:54'),
(26, 1, '0ea71ca8d1d717a3f0443b9ccd5660fd13a2bfd3e1a7bae9f91437505474adf9', '2026-10-02 21:39:20', '2026-10-02 13:39:20', '2026-10-02 13:39:59'),
(27, 2, '3dfdd786ad2ec857e9b155f80c4704a001ccf26792df80ba91fbf00acb36224e', '2026-10-02 21:40:12', '2026-10-02 13:40:12', NULL),
(28, 1, '9b0456f3cc9c0aabaafc32b727f9ad8e26ae42354820e5a563d519c52eaba039', '2026-10-02 21:47:58', '2026-10-02 13:47:58', '2026-10-02 13:48:02'),
(29, 1, '2fec09f15f41b530cbb44521b25b9c915eee0040de17454b41f7070b059181d9', '2026-10-02 21:48:10', '2026-10-02 13:48:10', '2026-10-02 13:48:25'),
(30, 1, 'fe981cb3ba7307c963a8a9807d95ebd1b006331e4bba2e63810b3afdfaa3b999', '2026-10-02 21:48:30', '2026-10-02 13:48:30', '2026-10-02 13:53:00'),
(31, 1, '0c305c798c0881625231d1fd1e0f3b2d4f33c89a646a1a1544ffd2eb126491a1', '2026-10-02 21:53:09', '2026-10-02 13:53:09', '2026-10-02 13:53:25'),
(32, 1, '04b49e9a3ac0da4dd2118ed72f09413a2cb984b6717d528177fd48ade354a0a6', '2026-10-02 21:53:29', '2026-10-02 13:53:29', '2026-10-02 14:08:11'),
(33, 1, '002f548c4b253e7b1ed2cc34c0a6d3859035076cd5e01d1f52fff0665b2aafad', '2026-10-02 22:08:26', '2026-10-02 14:08:26', '2026-10-02 14:10:26'),
(34, 2, '53983b999a1affba1b48451464351e77ce42645eac0f46fc4ed81ad3505ecbcc', '2026-10-02 22:08:47', '2026-10-02 14:08:47', NULL),
(35, 2, '078ae71adc43e97b360368521e9ca25980bc52bff3f77f9d16f691bec81ae42f', '2026-10-02 22:10:29', '2026-10-02 14:10:29', '2026-10-02 14:10:38'),
(36, 1, '9f5aaa15f7ee5c2d8b4ecbf62cefd73cee6006bdd58c85fd4bacbdfee829f20f', '2026-10-02 22:10:42', '2026-10-02 14:10:42', '2026-10-02 14:15:36'),
(37, 2, '6d8dd46b6627f1e5ec7323e9b250b525397834bf13ff230a401ad0ad97299302', '2026-10-02 22:15:41', '2026-10-02 14:15:41', '2026-10-02 14:27:28'),
(38, 1, '5fc3d8f0c129bf0f4b19242b2b981893b859f9728f02e597b465e24aa08d6fa9', '2026-10-02 22:27:32', '2026-10-02 14:27:32', '2026-10-02 14:27:36'),
(39, 2, '14bdec5fe98ac0a32a0f9c92068d7e96c938d1fd19e2e4480b2fa68a3e4ce9da', '2026-10-02 22:27:40', '2026-10-02 14:27:40', '2026-10-02 15:05:48');

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
  ADD KEY `idx_concerns_created_at` (`created_at`);

--
-- Indexes for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_attachments_concern` (`concern_id`),
  ADD KEY `idx_attachments_user` (`uploaded_by`);

--
-- Indexes for table `concern_comments`
--
ALTER TABLE `concern_comments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_comments_concern` (`concern_id`),
  ADD KEY `idx_comments_user` (`user_id`),
  ADD KEY `idx_comments_created_at` (`created_at`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `concern_comments`
--
ALTER TABLE `concern_comments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `concerns`
--
ALTER TABLE `concerns`
  ADD CONSTRAINT `fk_concerns_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_concerns_organization` FOREIGN KEY (`assigned_organization_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_concerns_type` FOREIGN KEY (`concern_type_id`) REFERENCES `concern_types` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  ADD CONSTRAINT `fk_attachments_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_attachments_user` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `concern_comments`
--
ALTER TABLE `concern_comments`
  ADD CONSTRAINT `fk_comments_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

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
