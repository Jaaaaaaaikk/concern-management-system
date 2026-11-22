-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               10.11.16-MariaDB - MariaDB Server
-- Server OS:                    Win64
-- HeidiSQL Version:             12.22.0.7382
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for concern_management
CREATE DATABASE IF NOT EXISTS `concern_management` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
USE `concern_management`;

-- Dumping structure for table concern_management.concern_attachments
CREATE TABLE IF NOT EXISTS `concern_attachments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `concern_id` bigint(20) unsigned NOT NULL,
  `comment_id` bigint(20) unsigned DEFAULT NULL,
  `uploaded_by` int(10) unsigned NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `file_size` bigint(20) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `edited_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_attachments_concern` (`concern_id`),
  KEY `idx_attachments_user` (`uploaded_by`),
  KEY `idx_attachments_comment` (`comment_id`),
  CONSTRAINT `fk_attachments_comment` FOREIGN KEY (`comment_id`) REFERENCES `concern_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_attachments_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_attachments_user` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.concern_attachments: ~0 rows (approximately)
INSERT INTO `concern_attachments` (`id`, `concern_id`, `comment_id`, `uploaded_by`, `file_name`, `file_path`, `file_type`, `file_size`, `created_at`, `edited_at`, `deleted_at`) VALUES
	(1, 1, NULL, 2, 'concern-1-1795149339129-fxwgl18s.jpg', '/uploads/concerns/concern-1-1795149339129-fxwgl18s.jpg', 'image/jpeg', 2821366, '2026-11-19 20:35:39', NULL, NULL);

-- Dumping structure for table concern_management.concern_comments
CREATE TABLE IF NOT EXISTS `concern_comments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `concern_id` bigint(20) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `comment` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_comments_concern` (`concern_id`),
  KEY `idx_comments_user` (`user_id`),
  KEY `idx_comments_created_at` (`created_at`),
  CONSTRAINT `fk_comments_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.concern_comments: ~0 rows (approximately)

-- Dumping structure for table concern_management.concern_status_attachments
CREATE TABLE IF NOT EXISTS `concern_status_attachments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `status_history_id` bigint(20) unsigned NOT NULL,
  `concern_id` bigint(20) unsigned NOT NULL,
  `uploaded_by` int(10) unsigned NOT NULL,
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_type` varchar(100) NOT NULL,
  `file_size` bigint(20) unsigned NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_status_history_id` (`status_history_id`),
  KEY `idx_concern_id` (`concern_id`),
  KEY `idx_uploaded_by` (`uploaded_by`),
  CONSTRAINT `fk_status_attachment_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_status_attachment_history` FOREIGN KEY (`status_history_id`) REFERENCES `concern_status_history` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table concern_management.concern_status_attachments: ~2 rows (approximately)
INSERT INTO `concern_status_attachments` (`id`, `status_history_id`, `concern_id`, `uploaded_by`, `file_name`, `file_path`, `file_type`, `file_size`, `created_at`) VALUES
	(1, 2, 1, 8, 'IMG_20261030_201244.jpg', '/uploads/concerns/status-1-34d4e911b37403a384302a645e257d14.jpg', 'image/jpeg', 1277828, '2026-11-19 20:48:07'),
	(2, 4, 1, 8, 'IMG_20261030_200755.jpg', '/uploads/concerns/status-1-b1ed8e0f4b483e54757a37630cb83e3e.jpg', 'image/jpeg', 1561205, '2026-11-19 20:51:08');

-- Dumping structure for table concern_management.concern_status_history
CREATE TABLE IF NOT EXISTS `concern_status_history` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `concern_id` bigint(20) unsigned NOT NULL,
  `changed_by` int(10) unsigned NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) NOT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_status_history_concern` (`concern_id`),
  KEY `idx_status_history_user` (`changed_by`),
  KEY `idx_status_history_created_at` (`created_at`),
  CONSTRAINT `fk_status_history_concern` FOREIGN KEY (`concern_id`) REFERENCES `concerns` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_status_history_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.concern_status_history: ~4 rows (approximately)
INSERT INTO `concern_status_history` (`id`, `concern_id`, `changed_by`, `old_status`, `new_status`, `remarks`, `created_at`) VALUES
	(1, 1, 8, 'pending', 'in_progress', 'we start working today.\nCommitment start: 2026-11-20', '2026-11-19 20:44:11'),
	(2, 1, 8, 'in_progress', 'resolved', 'we\'re done.', '2026-11-19 20:48:07'),
	(3, 1, 2, 'resolved', 'in_progress', 'we notice the problem was not yet done.', '2026-11-19 20:49:20'),
	(4, 1, 8, 'in_progress', 'resolved', 'its finally done.', '2026-11-19 20:51:08'),
	(5, 1, 2, 'resolved', 'closed', NULL, '2026-11-19 20:52:13');

-- Dumping structure for table concern_management.concern_types
CREATE TABLE IF NOT EXISTS `concern_types` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.concern_types: ~7 rows (approximately)
INSERT INTO `concern_types` (`id`, `name`, `description`, `status`, `created_at`, `updated_at`) VALUES
	(1, 'Civil and Architectural', NULL, 'active', '2026-11-19 19:51:15', '2026-11-19 19:51:15'),
	(2, 'MEFPS', NULL, 'inactive', '2026-11-19 19:51:27', '2026-11-19 19:52:57'),
	(3, 'Mechanical', NULL, 'active', '2026-11-19 19:53:07', '2026-11-19 19:53:07'),
	(4, 'Electrical', NULL, 'active', '2026-11-19 19:53:14', '2026-11-19 19:53:14'),
	(5, 'Plumbing', NULL, 'active', '2026-11-19 19:53:19', '2026-11-19 19:53:19'),
	(6, 'Fire Protection', NULL, 'active', '2026-11-19 19:53:45', '2026-11-19 19:53:45'),
	(7, 'FDAS', NULL, 'active', '2026-11-19 19:53:53', '2026-11-19 19:53:53');

-- Dumping structure for table concern_management.concerns
CREATE TABLE IF NOT EXISTS `concerns` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `concern_number` varchar(30) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `concern_type_id` int(10) unsigned DEFAULT NULL,
  `created_by` int(10) unsigned NOT NULL,
  `assigned_organization_id` int(10) unsigned DEFAULT NULL,
  `status` enum('pending','in_progress','on_hold','resolved','closed') NOT NULL DEFAULT 'pending',
  `priority` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `target_commitment_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `resolved_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `concern_number` (`concern_number`),
  KEY `idx_concerns_created_by` (`created_by`),
  KEY `idx_concerns_organization` (`assigned_organization_id`),
  KEY `idx_concerns_status` (`status`),
  KEY `idx_concerns_priority` (`priority`),
  KEY `idx_concerns_type` (`concern_type_id`),
  KEY `idx_concerns_created_at` (`created_at`),
  KEY `idx_concerns_deleted_at` (`deleted_at`),
  KEY `fk_concerns_deleted_by` (`deleted_by`),
  CONSTRAINT `fk_concerns_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_concerns_deleted_by` FOREIGN KEY (`deleted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_concerns_organization` FOREIGN KEY (`assigned_organization_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_concerns_type` FOREIGN KEY (`concern_type_id`) REFERENCES `concern_types` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.concerns: ~1 rows (approximately)
INSERT INTO `concerns` (`id`, `concern_number`, `title`, `description`, `concern_type_id`, `created_by`, `assigned_organization_id`, `status`, `priority`, `created_at`, `target_commitment_at`, `updated_at`, `resolved_at`, `closed_at`, `deleted_at`, `deleted_by`) VALUES
	(1, 'CON-2026-00001', 'Leaking', 'Leaking at 12th Floor Elevator Lobby', 1, 2, 3, 'closed', 'urgent', '2026-11-19 19:55:05', '2026-11-20 00:00:00', '2026-11-19 20:52:13', '2026-11-19 20:51:08', '2026-11-19 20:52:13', NULL, NULL);

-- Dumping structure for table concern_management.organization_concern_types
CREATE TABLE IF NOT EXISTS `organization_concern_types` (
  `organization_id` int(10) unsigned NOT NULL,
  `concern_type_id` int(10) unsigned NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`organization_id`,`concern_type_id`),
  KEY `idx_organization_concern_types_type` (`concern_type_id`),
  CONSTRAINT `fk_organization_concern_types_organization` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_organization_concern_types_type` FOREIGN KEY (`concern_type_id`) REFERENCES `concern_types` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.organization_concern_types: ~6 rows (approximately)
INSERT INTO `organization_concern_types` (`organization_id`, `concern_type_id`, `created_at`) VALUES
	(3, 1, '2026-11-19 19:51:16'),
	(3, 2, '2026-11-19 19:51:27'),
	(3, 3, '2026-11-19 19:53:07'),
	(3, 4, '2026-11-19 19:53:14'),
	(3, 5, '2026-11-19 19:53:19'),
	(3, 6, '2026-11-19 19:53:45'),
	(3, 7, '2026-11-19 19:53:53');

-- Dumping structure for table concern_management.organizations
CREATE TABLE IF NOT EXISTS `organizations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `organization_type` enum('bpo','tenant','admin_facilities') NOT NULL DEFAULT 'tenant',
  `description` text DEFAULT NULL,
  `contact_email` varchar(150) DEFAULT NULL,
  `contact_number` varchar(50) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` datetime DEFAULT NULL,
  `created_by` int(10) unsigned DEFAULT NULL,
  `updated_by` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_organization_name` (`name`),
  KEY `idx_organization_status` (`status`),
  KEY `idx_organizations_created_by` (`created_by`),
  KEY `idx_organizations_updated_by` (`updated_by`),
  CONSTRAINT `fk_organizations_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_organizations_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.organizations: ~9 rows (approximately)
INSERT INTO `organizations` (`id`, `name`, `organization_type`, `description`, `contact_email`, `contact_number`, `address`, `status`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`) VALUES
	(1, 'ICT Department', 'admin_facilities', 'Felcris Centrale ICT Department', NULL, NULL, 'UG Alfresco Building A', 'active', '2026-10-01 21:22:29', '2026-10-16 17:21:22', NULL, NULL, NULL),
	(2, 'VXI', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale Building A', 'active', '2026-10-02 11:44:39', '2026-10-12 13:41:32', NULL, NULL, NULL),
	(3, 'Engineering Department', 'admin_facilities', 'Felcris Centrale Engineering Team', NULL, NULL, 'Felcris Centrale UG Parking', 'active', '2026-10-02 14:09:36', '2026-10-15 15:02:39', NULL, NULL, 1),
	(4, 'Optum', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale 8th Floor', 'active', '2026-10-09 15:19:29', '2026-10-16 17:23:58', NULL, NULL, 1),
	(5, 'TelePerformance', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale UG Building C', 'active', '2026-10-09 15:20:30', '2026-10-16 17:23:00', NULL, NULL, 1),
	(6, 'IBEX', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale Building C', 'active', '2026-10-09 15:20:55', '2026-10-16 17:24:08', NULL, NULL, 1),
	(7, 'Regus', 'tenant', 'Tenant', NULL, NULL, 'Felcris Centrale Building A 6th Floor', 'active', '2026-10-09 15:21:43', '2026-10-16 17:22:48', NULL, NULL, 1),
	(8, 'Intellicare', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale Building C 4th Floor', 'active', '2026-10-09 15:22:16', '2026-10-16 17:23:46', NULL, NULL, 1),
	(9, 'Safety and Security (SSI)', 'admin_facilities', 'Felcris Centrale EHSS Department', NULL, NULL, 'EHSS Department', 'active', '2026-10-14 08:25:40', '2026-10-16 17:21:54', NULL, 1, 1);

-- Dumping structure for table concern_management.roles
CREATE TABLE IF NOT EXISTS `roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.roles: ~5 rows (approximately)
INSERT INTO `roles` (`id`, `name`, `description`, `created_at`, `updated_at`) VALUES
	(1, 'superadmin', 'Full system access and user management', '2026-10-01 21:22:29', '2026-10-01 21:22:29'),
	(2, 'concern_handler', 'Handles assigned concerns and manages their status', '2026-10-01 21:22:29', '2026-10-14 08:20:13'),
	(3, 'requestor', 'Creates concerns and participates in authorized conversations', '2026-10-01 21:22:29', '2026-10-14 08:20:13'),
	(4, 'system_admin', 'Manages system-wide concerns, organizations, and user accounts; cannot manage superadmin accounts or revoke sessions', '2026-10-14 08:20:13', '2026-10-14 08:20:13'),
	(5, 'system_monitor', 'Views system-wide concerns and dashboards and may comment; cannot create concerns or change statuses', '2026-10-14 08:20:13', '2026-10-14 08:20:13');

-- Dumping structure for table concern_management.user_sessions
CREATE TABLE IF NOT EXISTS `user_sessions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `session_token_hash` char(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `revoked_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `session_token_hash` (`session_token_hash`),
  KEY `idx_sessions_user` (`user_id`),
  KEY `idx_sessions_expires` (`expires_at`),
  KEY `idx_sessions_revoked` (`revoked_at`),
  KEY `idx_user_sessions_created_at` (`created_at`),
  CONSTRAINT `fk_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.user_sessions: ~47 rows (approximately)
INSERT INTO `user_sessions` (`id`, `user_id`, `session_token_hash`, `expires_at`, `created_at`, `revoked_at`) VALUES
	(1, 1, '73e913409a9e101a90fd1c0e48db1c97ec214810a6b586e7062116a196bc57c2', '2026-11-19 03:39:31', '2026-11-18 19:39:31', '2026-11-19 00:03:51'),
	(2, 1, '3ad6ccb65159e9de02d80400ae13cfab586fecd65e8baa4908091ee1147aa53f', '2026-11-19 03:42:39', '2026-11-18 19:42:39', '2026-11-19 00:03:04'),
	(3, 1, '35efa597e12976dd44e44f60b58e4992b76647046b8e1e3c8b8b86514f382a1f', '2026-11-19 03:43:10', '2026-11-18 19:43:10', '2026-11-18 19:43:38'),
	(4, 1, 'a299b29c55421d2461f64c8d73adee56ecce31ecf50f6cf60ab9951c046fb6ec', '2026-11-19 03:44:03', '2026-11-18 19:44:03', '2026-11-19 00:02:56'),
	(5, 1, '649cbdb3fe42eba2a317939df650bed0244e87ff55b50467a88fc4bb8fa18b2d', '2026-11-19 03:49:55', '2026-11-18 19:49:55', '2026-11-18 19:50:28'),
	(6, 1, '0e864543df5354dc06e3776bad378bab5a1f14208254e4cb1fd1a2ad2563d75c', '2026-11-19 05:24:24', '2026-11-18 21:24:24', '2026-11-19 00:02:49'),
	(7, 1, '8273095288ef0d09042880deb7cc28e6957f2af271da8fef100c3986fa39341d', '2026-11-19 08:02:22', '2026-11-19 00:02:22', NULL),
	(8, 1, 'e6bb18661119833abcdfc7aa2856bac6c4623cc664f00b484c2b7177e1564282', '2026-11-19 08:03:27', '2026-11-19 00:03:27', '2026-11-19 00:05:20'),
	(9, 1, 'a7b5c07613e9dc726e0fdb556ea768a0dc8b81e66a863fac28b05d5bd52e0905', '2026-11-19 08:05:49', '2026-11-19 00:05:49', '2026-11-19 00:16:06'),
	(10, 1, '170475bc9ae6913c6988a63a1aff04f550597c599d900de1a0e19c89b70de707', '2026-11-19 08:08:14', '2026-11-19 00:08:14', '2026-11-19 00:11:08'),
	(11, 1, 'f7a2ff20904fd7e47b189ca729a260e00968a69e311d65b5217209a0be95e707', '2026-11-19 08:22:23', '2026-11-19 00:22:23', NULL),
	(12, 1, '5338c773ea92101a97c287475b811450e84839a6dcfbaeff3b8513380cf691a4', '2026-11-19 09:34:46', '2026-11-19 01:34:46', '2026-11-19 01:34:49'),
	(13, 1, '61e348a70b7c81d669011b251640945656427c07f199f0f8296dfb8338f5cd08', '2026-11-19 23:49:13', '2026-11-19 15:49:13', '2026-11-19 15:50:15'),
	(14, 1, 'cfed41011830646935244093388143d4d71585919b8e56e8e30c265cbfef7441', '2026-11-20 00:18:33', '2026-11-19 16:18:33', '2026-11-19 16:27:55'),
	(15, 1, 'c64fb802a932c8109d25aa2909f621255e00d53898ee6cfa327663b5a57b0b46', '2026-11-20 00:28:56', '2026-11-19 16:28:56', '2026-11-19 16:31:29'),
	(16, 1, '23c4328b625ea109186dd4aa3712f7dd374b2fd978c04d56bfe12f275d44be29', '2026-11-20 00:31:54', '2026-11-19 16:31:54', '2026-11-19 16:32:14'),
	(17, 1, 'f08ccce19a1769a1926e437ed85e92acb1e72c65c1cf65e7f80683ef840a8ea8', '2026-11-20 00:32:36', '2026-11-19 16:32:36', '2026-11-19 16:52:05'),
	(18, 1, 'e8dfff5f80e19cbd77c26c945f44bf15021a3ea11434e0743c4bcbaa855155d6', '2026-11-20 00:52:30', '2026-11-19 16:52:30', '2026-11-19 17:16:10'),
	(19, 1, '0f5436c4289e662e9ba6171f66874c12850a52619fa4fb312a2fb04a0400c7c7', '2026-11-20 01:16:41', '2026-11-19 17:16:41', '2026-11-19 17:16:50'),
	(20, 1, '5086f3d2f98177fb0a5e0649ada65e432e476f7d9579b36a0acc629f80b39477', '2026-11-20 01:24:29', '2026-11-19 17:24:29', '2026-11-19 17:25:00'),
	(21, 1, '96559f65d3e81579bb469a6305fb79c05b206fb5578959b985b1678020cb6a0b', '2026-11-20 01:25:57', '2026-11-19 17:25:57', '2026-11-19 17:26:13'),
	(22, 1, '383995871b2593de765e054966a8dae8ccdbeba4b675d189f9a23b444a631a1a', '2026-11-20 01:26:26', '2026-11-19 17:26:26', '2026-11-19 17:26:33'),
	(23, 1, 'e813893edfd4758087918883081c83e64eec158aba30ff9d3aed4d32bf27e010', '2026-11-20 01:38:10', '2026-11-19 17:38:10', '2026-11-19 17:38:31'),
	(24, 1, 'e74f89b18c9fd6a72bd8651d2f979e3d5fd1ac0f393c67fc32c859b5407e1513', '2026-11-20 02:37:24', '2026-11-19 18:37:24', '2026-11-19 18:37:39'),
	(25, 1, '2cbd8615035c1c21d16ab14ce7a406f3d2e8ec211f3e0422a0699934bef4e0cb', '2026-11-20 03:07:02', '2026-11-19 19:07:02', '2026-11-19 19:10:05'),
	(26, 1, 'c415ced20119a02a759e2aff69d718f3ccbe8e1e728e7b2a776a4549c1799a3e', '2026-11-20 03:09:50', '2026-11-19 19:09:50', '2026-11-19 19:10:09'),
	(27, 1, '3a08e1f77444a9402dbf14eea98e425362da9654cd329aa4e405579d13ab0bdf', '2026-11-20 03:42:01', '2026-11-19 19:42:01', '2026-11-19 19:42:03'),
	(28, 1, '5f2a34f416e79d8601aa880a2b4c0aece0544bcfadbd0c62e7f47e56e330f755', '2026-11-20 03:42:23', '2026-11-19 19:42:23', '2026-11-19 19:49:02'),
	(29, 2, '614cc053e33d2875b515d94621c39d36318ea80e96eb304bb727240d3134b38e', '2026-11-20 03:49:15', '2026-11-19 19:49:15', '2026-11-19 19:49:45'),
	(30, 1, '74586125d564ff1a15508ba9d0c7e2bfb2868027065b4d4582cee0a346726feb', '2026-11-20 03:49:58', '2026-11-19 19:49:58', '2026-11-19 19:51:29'),
	(31, 2, '1d20cdafa972a0bd79e0fc688948431ff4c3535403e0d62cff4344ae2a879166', '2026-11-20 03:51:35', '2026-11-19 19:51:35', '2026-11-19 19:51:38'),
	(32, 1, 'f33293b097b5a89b28ce3e720c3e9d1aaa5f887bb01a5c19b034f98bab065d72', '2026-11-20 03:51:50', '2026-11-19 19:51:50', '2026-11-19 19:53:55'),
	(33, 2, '47b719cf91d126e5914829cce1dbf4bed2a65985a66f4ed4659286e6b57a302e', '2026-11-20 03:54:11', '2026-11-19 19:54:11', '2026-11-19 19:55:15'),
	(34, 1, '41952adf061eaaf75349ae145e372337bb0d648485b8b09cb4bbedf2f55231bc', '2026-11-20 03:55:34', '2026-11-19 19:55:34', '2026-11-19 20:34:40'),
	(35, 8, '7949a1f09e4aaa18d16bc1b6bf23f79fc96ef23a52b11a50ea0e1df7671c76b0', '2026-11-20 03:58:26', '2026-11-19 19:58:26', NULL),
	(36, 2, '75c483c0acf91f0e09a74e76fddf5ee27edcbf7d3e37299438b1d34fc56c5ecb', '2026-11-20 04:34:47', '2026-11-19 20:34:47', '2026-11-19 20:36:01'),
	(37, 8, '1bf754529465e23aab0309883823ce2b0b61ed639a3b116422267b9df54d5b65', '2026-11-20 04:36:14', '2026-11-19 20:36:14', '2026-11-19 20:48:21'),
	(38, 2, 'fe143ad110fcc807eb5b92c46ebd2c35e0356ea382bb5e6c9dcb46aa29b01f78', '2026-11-20 04:48:49', '2026-11-19 20:48:49', '2026-11-19 20:50:29'),
	(39, 8, 'bb9693671cf6de5c17c3d7d1412e4db22c5344cdba312578d44fcf34b118cab6', '2026-11-20 04:50:42', '2026-11-19 20:50:42', '2026-11-19 20:51:11'),
	(40, 2, '637842a3a45625496fd223c73e4832fa14cc205647a4a40dedd820c62669a7a5', '2026-11-20 04:51:18', '2026-11-19 20:51:18', '2026-11-19 20:58:33'),
	(41, 1, '744a0af2ce5bad2ecb6d3ac9c6c25fba873bff818550206ce0d2446ce334decc', '2026-11-20 05:00:53', '2026-11-19 21:00:53', '2026-11-19 21:01:26'),
	(42, 1, '3d0b9aeeb40712554220bc3ab60e0f7c8b315f7515153ad1ef27aa90595c9c4e', '2026-11-20 05:01:38', '2026-11-19 21:01:38', '2026-11-19 21:01:57'),
	(43, 1, 'a0f3bf4a877c39c8eb66fc4b6b6dc103c35116d8fe4bae900c29a2bb75084b1b', '2026-11-20 05:02:12', '2026-11-19 21:02:12', '2026-11-19 21:02:15'),
	(44, 1, '0e8b84c0b0396b531e0442176801eeaf2f0a4ded5db4cf7e2806d6299ddc2185', '2026-11-20 05:02:40', '2026-11-19 21:02:40', '2026-11-19 21:02:43'),
	(45, 1, '4769528aaefae3e131ec8364d25c65f2f768d4573486db750a7298cee264ee22', '2026-11-20 22:11:11', '2026-11-20 14:11:11', '2026-11-20 14:11:42'),
	(46, 2, '3efa0f719d19c51806a562768340de58d8e939306154cc1e410e07dfc5119c4b', '2026-11-20 22:12:10', '2026-11-20 14:12:10', '2026-11-20 14:12:43'),
	(47, 1, '8fd87ff0291af1d825df83bc14589f810b7f6fa62034420dd5e49eb258cee5f6', '2026-11-21 03:41:23', '2026-11-20 19:41:23', '2026-11-20 19:41:36');

-- Dumping structure for table concern_management.users
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `middle_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) NOT NULL,
  `role_id` int(10) unsigned NOT NULL,
  `organization_id` int(10) unsigned DEFAULT NULL,
  `profile_photo` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','suspended') NOT NULL DEFAULT 'active',
  `last_login_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `deleted_at` datetime DEFAULT NULL,
  `created_by` int(10) unsigned DEFAULT NULL,
  `updated_by` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `idx_users_role` (`role_id`),
  KEY `idx_users_organization` (`organization_id`),
  KEY `idx_users_status` (`status`),
  KEY `idx_users_name` (`last_name`,`first_name`),
  KEY `idx_users_created_by` (`created_by`),
  KEY `idx_users_updated_by` (`updated_by`),
  CONSTRAINT `fk_users_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_users_organization` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_users_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table concern_management.users: ~8 rows (approximately)
INSERT INTO `users` (`id`, `username`, `password_hash`, `first_name`, `middle_name`, `last_name`, `role_id`, `organization_id`, `profile_photo`, `status`, `last_login_at`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`) VALUES
	(1, 'superadmin', '$2b$10$BeoIWCGnWk0gXY.VwTDkQuX0vqgL/E3rpP/SR6UW2XZ/IGlguKZ.6', 'Super', NULL, 'Administrator', 1, NULL, '/uploads/users/4718edb9-cce9-48da-ac86-5efe55d8a69c.png', 'active', '2026-11-20 19:41:22', '2026-10-01 21:22:29', '2026-11-20 19:41:22', NULL, NULL, 1),
	(2, 'vxi', '$2b$10$VX/mWgaS4.BvJBWWHBAGO.eijlRUjMOBFZBLFqK3/RLRPGgOfYPCq', 'VXI', NULL, 'Company', 2, 2, NULL, 'active', '2026-11-20 14:12:10', '2026-11-19 19:45:02', '2026-11-20 14:12:10', NULL, 1, 1),
	(3, 'optum', '$2b$10$awsmEWFwjOwXOEVEjUyyxOtPJXoCuPem.G8DEOQR4Evt4k/JMCAeu', 'Optum', NULL, 'Company', 2, 4, NULL, 'active', NULL, '2026-11-19 19:45:31', '2026-11-19 19:45:31', NULL, 1, 1),
	(4, 'ibex', '$2b$10$9BG35ODsTg42/Wyt69OSMOtAaa7dkdDTzEKV.vDE1A35SBBPdavT.', 'Ibex', NULL, 'Company', 2, 6, NULL, 'active', NULL, '2026-11-19 19:46:18', '2026-11-19 19:46:18', NULL, 1, 1),
	(5, 'intellicare', '$2b$10$P/AAlXOBzHmeirGFM10jseJz2urNk6IyaZUBmDeW6L6bE4RwbwZIm', 'Intellicare', NULL, 'Company', 2, 8, NULL, 'active', NULL, '2026-11-19 19:46:58', '2026-11-19 19:46:58', NULL, 1, 1),
	(6, 'regus', '$2b$10$zgGU5tD89HL6jgV1s/MsOOd/DNrRmGcdf5fOAr3tk3ZhJMeedWCTq', 'Regus', NULL, 'Company', 2, 7, NULL, 'active', NULL, '2026-11-19 19:47:27', '2026-11-19 19:47:27', NULL, 1, 1),
	(7, 'tp', '$2b$10$1asd/IWJCVojFxz6AaUACeIfOPbTmPafvoQMnm9OgcUbatMWhleQy', 'Teleperformance', NULL, 'Company', 2, 5, NULL, 'active', NULL, '2026-11-19 19:48:33', '2026-11-19 19:48:33', NULL, 1, 1),
	(8, 'john.sinajon', '$2b$10$s5JKYHboXjyO3Z9YHesGeeQcn5EPNN3dh7GpH187Z6LC1aNl0B2sG', 'John', NULL, 'Sinajon', 2, 3, NULL, 'active', '2026-11-19 20:50:42', '2026-11-19 19:57:22', '2026-11-19 20:50:42', NULL, 1, 1);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
