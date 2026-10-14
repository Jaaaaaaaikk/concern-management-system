-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 15, 2026 at 01:09 AM
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

--
-- Dumping data for table `concerns`
--

INSERT INTO `concerns` (`id`, `concern_number`, `title`, `description`, `concern_type_id`, `created_by`, `assigned_organization_id`, `status`, `priority`, `created_at`, `target_commitment_at`, `updated_at`, `resolved_at`, `closed_at`, `deleted_at`, `deleted_by`) VALUES
(1, 'CON-2026-00001', 'water leaks', 'water leaks at 3rd floor male cr', 3, 4, 3, 'in_progress', 'high', '2026-10-12 10:57:35', '2026-10-12 11:06:00', '2026-10-12 11:06:01', NULL, NULL, NULL, NULL),
(2, 'CON-2026-00002', 'wall crack', 'wall crack at elevator looby 4th floor', 3, 7, 3, 'resolved', 'medium', '2026-10-12 10:59:26', '2026-10-12 11:05:00', '2026-10-12 13:11:07', '2026-10-12 13:11:07', NULL, NULL, NULL),
(3, 'CON-2026-00003', 'repaint', 'repaint wall at 5th floor female cr', 3, 7, 3, 'pending', 'medium', '2026-10-12 11:14:54', NULL, '2026-10-12 11:14:54', NULL, NULL, NULL, NULL);

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

--
-- Dumping data for table `concern_attachments`
--

INSERT INTO `concern_attachments` (`id`, `concern_id`, `comment_id`, `uploaded_by`, `file_name`, `file_path`, `file_type`, `file_size`, `created_at`, `edited_at`, `deleted_at`) VALUES
(1, 1, NULL, 4, 'sample-image.jpg', '/uploads/concerns/concern-1-3ab501599cd16241fab7eacde358262c.jpg', 'image/jpeg', 25757, '2026-10-12 10:57:35', NULL, NULL),
(2, 2, NULL, 7, 'images.jpg', '/uploads/concerns/concern-2-2d68ae34d2051bf7521838fa0a1ed584.jpg', 'image/jpeg', 39574, '2026-10-12 10:59:26', NULL, NULL),
(3, 3, NULL, 7, 'images (1).jpg', '/uploads/concerns/concern-3-f141b268b51d87fc4826f4924d5c8952.jpg', 'image/jpeg', 20271, '2026-10-12 11:14:54', NULL, NULL),
(4, 2, 1, 7, 'images.jpg', '/uploads/concerns/comment-1-1791781453363-bc204d2abbbb78.jpg', 'image/jpeg', 39574, '2026-10-12 13:04:13', NULL, NULL);

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
(1, 2, 7, '', '2026-10-12 13:04:13', '2026-10-12 13:04:13');

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

--
-- Dumping data for table `concern_status_attachments`
--

INSERT INTO `concern_status_attachments` (`id`, `status_history_id`, `concern_id`, `uploaded_by`, `file_name`, `file_path`, `file_type`, `file_size`, `created_at`) VALUES
(1, 3, 2, 5, 'images (1).jpg', '/uploads/concerns/status-2-8127395bb1c028d373439cdf3b20d26c.jpg', 'image/jpeg', 20271, '2026-10-12 11:10:50'),
(2, 5, 2, 8, 'images (1).jpg', '/uploads/concerns/status-2-381e46627c5ac1c8c5b6fbfe7358b064.jpg', 'image/jpeg', 20271, '2026-10-12 13:11:07');

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

--
-- Dumping data for table `concern_status_history`
--

INSERT INTO `concern_status_history` (`id`, `concern_id`, `changed_by`, `old_status`, `new_status`, `remarks`, `created_at`) VALUES
(1, 2, 5, 'pending', 'in_progress', 'we already acknowledge\nCommitment start: 2026-10-12 11:05:00', '2026-10-12 11:04:31'),
(2, 1, 5, 'pending', 'in_progress', 'already acknowledge\nCommitment start: 2026-10-12 11:06:00', '2026-10-12 11:06:01'),
(3, 2, 5, 'in_progress', 'resolved', 'already resolved', '2026-10-12 11:10:50'),
(4, 2, 7, 'resolved', 'in_progress', 'thiers another concern left need to fixwd it.', '2026-10-12 13:03:57'),
(5, 2, 8, 'in_progress', 'resolved', 'already fixed', '2026-10-12 13:11:07');

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
(1, 'IT / Technical', 'Computer, software, hardware, network, and technical concerns', 'inactive', '2026-10-01 21:22:29', '2026-10-12 09:55:16'),
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
  `deleted_at` datetime DEFAULT NULL,
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `updated_by` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `organizations`
--

INSERT INTO `organizations` (`id`, `name`, `organization_type`, `description`, `contact_email`, `contact_number`, `address`, `status`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`) VALUES
(1, 'IT Department', 'admin_facilities', 'Information Technology Department', NULL, NULL, 'UG Alfresco Building A', 'active', '2026-10-01 21:22:29', '2026-10-12 13:41:32', NULL, NULL, NULL),
(2, 'VXI', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale Building A', 'active', '2026-10-02 11:44:39', '2026-10-12 13:41:32', NULL, NULL, NULL),
(3, 'Engineering Department', 'admin_facilities', 'Felcris Centrale Engineering Team', NULL, NULL, 'Felcris Centrale UG Parking', 'active', '2026-10-02 14:09:36', '2026-10-14 10:17:56', NULL, NULL, 10),
(4, 'Optum', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:19:29', '2026-10-12 13:41:32', NULL, NULL, NULL),
(5, 'TelePerformance', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:20:30', '2026-10-12 13:41:32', NULL, NULL, NULL),
(6, 'IBEX', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:20:55', '2026-10-12 13:41:32', NULL, NULL, NULL),
(7, 'Regus', 'tenant', NULL, NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:21:43', '2026-10-09 15:21:43', NULL, NULL, NULL),
(8, 'Intellicare', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:22:16', '2026-10-12 13:41:32', NULL, NULL, NULL),
(9, 'Safety and Security', 'admin_facilities', 'Safety', NULL, NULL, 'EHSS Department', 'active', '2026-10-14 08:25:40', '2026-10-14 08:25:50', NULL, 1, 1);

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
(2, 'concern_handler', 'Handles assigned concerns and manages their status', '2026-10-01 21:22:29', '2026-10-14 08:20:13'),
(3, 'requestor', 'Creates concerns and participates in authorized conversations', '2026-10-01 21:22:29', '2026-10-14 08:20:13'),
(4, 'system_admin', 'Manages system-wide concerns, organizations, and user accounts; cannot manage superadmin accounts or revoke sessions', '2026-10-14 08:20:13', '2026-10-14 08:20:13'),
(5, 'system_monitor', 'Views system-wide concerns and dashboards and may comment; cannot create concerns or change statuses', '2026-10-14 08:20:13', '2026-10-14 08:20:13');

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
  `deleted_at` datetime DEFAULT NULL,
  `created_by` int(10) UNSIGNED DEFAULT NULL,
  `updated_by` int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password_hash`, `first_name`, `middle_name`, `last_name`, `role_id`, `organization_id`, `profile_photo`, `status`, `last_login_at`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`) VALUES
(1, 'superadmin', '$2b$12$7Q2BZNGJ8VG8/aX288L7zextU/UWOthz0MWQarPSPUik6UwaYlnXK', 'Super', NULL, 'Administrator', 1, NULL, '/uploads/users/0f5206e8-6c0d-46cc-9b3f-a59d4ee8e31c.png', 'active', '2026-10-15 07:08:25', '2026-10-01 21:22:29', '2026-10-15 07:08:25', NULL, NULL, NULL),
(3, 'Robert', '$2b$12$0a9dLkqNwjRTmSermDEdcO5zQDreMVGFlOeoebF3yfu2g8jhpqLGe', 'Robert', NULL, 'Cabungcag', 5, 3, NULL, 'active', '2026-10-14 13:10:41', '2026-10-03 21:36:12', '2026-10-14 13:10:41', NULL, NULL, 3),
(4, 'VXI', '$2b$12$a2B3ATk3m2JvGo6mc/HiLOdSCRLp8vgUnWj.9FMUcmY1cIvm/Ymyq', 'VXI', NULL, 'BPO', 2, 2, NULL, 'active', '2026-10-12 11:59:12', '2026-10-03 21:46:59', '2026-10-12 11:59:12', NULL, NULL, NULL),
(5, 'BAO', '$2b$12$54wpUtxpdJFt/GkPVsp4keSo9fO1Ufws7wDboouXj3PBoUChAmmhe', 'BAO', NULL, 'Engineering', 2, 3, NULL, 'active', '2026-10-14 14:43:11', '2026-10-03 21:48:33', '2026-10-14 14:43:11', NULL, NULL, NULL),
(6, 'sample', '$2b$12$p7PWE8B6Awwdjx5zob.sRuv/xW6Yly/ErTIouWyUoZKO/rK131LaC', 'sample', NULL, 'user', 3, 3, NULL, 'active', '2026-10-14 12:48:37', '2026-10-04 22:13:40', '2026-10-14 12:48:37', NULL, NULL, NULL),
(7, 'Ibex', '$2b$12$bwT9UW78tZcR8TjFsMYvcegv7SfnZ2wSEDxD5N0nFR75WNq0Rk.zC', 'Ibex', NULL, 'BPO', 2, 6, NULL, 'active', '2026-10-14 15:14:08', '2026-10-12 10:55:39', '2026-10-14 15:14:08', NULL, NULL, NULL),
(8, 'John Lyndon', '$2b$12$ykmq8wpKlpypifL8jQRnw.Q7S.Ikqn5pfOJLu9H9S3w1WPy94/6Xa', 'John Lyndon', NULL, 'Sinajon', 2, 3, NULL, 'active', '2026-10-12 16:01:07', '2026-10-12 11:24:28', '2026-10-12 16:01:07', NULL, NULL, NULL),
(9, 'regus', '$2b$12$3bUvk.YiOr29QmDL5REovu890QhqLAipEKRv9lQcEMiGMZTIRBkaG', 'regus', NULL, 'regus', 2, 7, NULL, 'active', '2026-10-14 09:32:20', '2026-10-14 08:28:52', '2026-10-14 09:32:20', NULL, 1, 1),
(10, 'jaikhene', '$2b$12$QluZQ3HgRw14vO8hSei2/eCQFzxH/PF1HigVbGeYxOSUGuFZy5UA2', 'Jaikhene', NULL, 'Villar', 4, NULL, NULL, 'active', '2026-10-14 11:55:41', '2026-10-14 08:31:07', '2026-10-14 11:55:41', NULL, 1, 1),
(11, 'jerick', '$2b$12$wprPv9tC1Y72M7FHP4ZxUehZSSXTGXiU5E5N7K3waFDj7PUVAyIWa', 'Jerick', NULL, 'Espina', 4, NULL, NULL, 'active', '2026-10-14 10:51:20', '2026-10-14 10:51:12', '2026-10-14 10:51:58', NULL, 1, 11);

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
(2, 5, '76844da5417b7f53553ce972b0e7b66c4a21d0db5f6daf210032d2469c4de585', '2026-10-12 17:36:43', '2026-10-12 09:36:43', '2026-10-12 09:44:38'),
(3, 1, '237a2a5d3c12d2da4cbe60533156309ed0c3b99468f4810600daac5370b5cd15', '2026-10-12 17:44:44', '2026-10-12 09:44:44', '2026-10-12 10:53:04'),
(4, 1, '4f27adc9c8d6066748de7c50ba70a968090d75f69511eeae199afc93842427eb', '2026-10-12 17:54:51', '2026-10-12 09:54:51', '2026-10-12 10:00:18'),
(5, 3, '88f786dc8a20a1ffe9a2a15858d6fe0012d3cd3f77ae99bbd0e0f97bd98cad4e', '2026-10-12 18:00:27', '2026-10-12 10:00:27', '2026-10-12 10:43:11'),
(6, 1, 'f6d8957cbf0904004ac154671e67f9c74e120b65f55b181704e25188c9915f14', '2026-10-12 18:43:14', '2026-10-12 10:43:14', '2026-10-12 10:44:11'),
(7, 4, 'd738aaacb18ee498bb106ae0dbdb10d9ceb2cdcd4ce343a51c07697e961c0497', '2026-10-12 18:44:17', '2026-10-12 10:44:17', '2026-10-12 10:44:32'),
(8, 5, '2d5007084acc5f7056bdef5e56f79e291ede0120d044bcf139942c5427f48cbe', '2026-10-12 18:44:38', '2026-10-12 10:44:38', '2026-10-12 10:45:16'),
(9, 4, '18fd837c52bcaa2679baf3ab3c19ac573f9792d79fa88f0ad204390369d95d00', '2026-10-12 18:45:20', '2026-10-12 10:45:20', '2026-10-12 10:47:55'),
(10, 5, '9db27f5245f41e4763128a27e5fc1de1248b7f140944f2f82418ce1e730ff77f', '2026-10-12 18:53:08', '2026-10-12 10:53:08', '2026-10-12 10:53:16'),
(11, 4, 'ad855ed8e180cf8ec0743f73de55845579160ab36c0bf5c6a888658e408bcd19', '2026-10-12 18:53:20', '2026-10-12 10:53:20', '2026-10-12 11:02:12'),
(12, 4, '072bf0073aa84b18c950b3acddb80db91ebff9357925455128491df9d80c4300', '2026-10-12 18:53:39', '2026-10-12 10:53:39', '2026-10-12 10:53:58'),
(13, 5, '09b77269aa5d04be6c6b71117ea6252cfbeb7509a65c095f60f55b7f309b4497', '2026-10-12 18:54:03', '2026-10-12 10:54:03', '2026-10-12 10:54:23'),
(14, 6, '980fbfa7cf291cd5ea24de7a97ff3a08cdc4891ede04096c03d0e976e1711793', '2026-10-12 18:54:29', '2026-10-12 10:54:29', '2026-10-12 10:54:47'),
(15, 1, '557a9ca28ddc9ab93fce82cbbc59e5fe9c228158974b170ed65764292f66566a', '2026-10-12 18:54:49', '2026-10-12 10:54:49', '2026-10-12 10:55:44'),
(16, 7, '6c9c28a32205ff784e244d0140441413acaee0761c15dd568bc52859696bda05', '2026-10-12 18:55:49', '2026-10-12 10:55:49', '2026-10-12 10:56:27'),
(17, 4, '03af51eba6862ae4c966e0fe97e001946500bafeddfbe9f24ffc2282989b23dc', '2026-10-12 18:56:34', '2026-10-12 10:56:34', '2026-10-12 10:57:49'),
(18, 7, '9cd3cf3ea39218668442dc4ff9771102be960301c40507e4edc0d893df43a27d', '2026-10-12 18:57:55', '2026-10-12 10:57:55', '2026-10-12 10:59:36'),
(19, 5, 'dfd66b930dbc8668e6a292968beaa6d20e3bcf45f1da0b5b9bf5d38ab28e4154', '2026-10-12 18:59:41', '2026-10-12 10:59:41', '2026-10-12 11:07:26'),
(20, 1, '205c6e5a3ff62e85d083f0701b94f7d0c3dbcb21e8aa68b5bf5839cbdb4522ac', '2026-10-12 19:03:10', '2026-10-12 11:03:10', '2026-10-12 11:03:39'),
(21, 5, 'c1993904239df20ec7e0b1b0ca1519229caa0d1da4485643f34ea2589919f476', '2026-10-12 19:05:31', '2026-10-12 11:05:31', '2026-10-12 11:06:06'),
(22, 1, '97f8337f5cd0ac5f505e78a5eba8999fe557a8e609e9592d9bbaaef5217ee7da', '2026-10-12 19:06:17', '2026-10-12 11:06:17', '2026-10-12 11:10:17'),
(23, 7, '62ae0a6e7cca26d332d1908508652c16aaff98dc87a9fd95d65dd323cebfacbc', '2026-10-12 19:07:35', '2026-10-12 11:07:35', '2026-10-12 11:09:17'),
(24, 5, '8aa15a8c9b4084aa86d372ce81dc1c2b17e50ecff8a31a05867d2d893c64ff66', '2026-10-12 19:09:21', '2026-10-12 11:09:21', '2026-10-12 11:10:58'),
(25, 5, '072434068a2bc0646e983734148fe97b1c4ed6c52683ea186fc7479c92e69874', '2026-10-12 19:10:21', '2026-10-12 11:10:21', '2026-10-12 11:44:35'),
(26, 7, '6b1aee46c1bcb82d8858fd2702013de475ad567934942e0e01ab37f757a6d170', '2026-10-12 19:11:06', '2026-10-12 11:11:06', '2026-10-12 11:15:58'),
(27, 1, '84cb1b3099cab2592fe5c8f66689fbb444e14ab923b6676f7fbb71380a04abe6', '2026-10-12 19:16:01', '2026-10-12 11:16:01', '2026-10-12 11:19:24'),
(28, 1, '223f241831b228eee4b648aa37efcf09beba1d7d0595cc6afc7fbca1a82a24af', '2026-10-12 19:19:49', '2026-10-12 11:19:49', '2026-10-12 11:25:18'),
(29, 3, '4a6fc0858802724bd722d9ff907642086741bddaf67c1f0c2915e6045166ffec', '2026-10-12 19:25:25', '2026-10-12 11:25:25', '2026-10-12 11:26:34'),
(30, 1, 'a8afe3084bc7136c4183cde0b8c317be48ea3a8a216396ea0c36d7b8dae6b85f', '2026-10-12 19:26:37', '2026-10-12 11:26:37', '2026-10-12 11:35:00'),
(31, 8, 'f9e59e192d7ab9d5c8256a1faddf73068c96c0416a288f4595a4604d46623976', '2026-10-12 19:35:14', '2026-10-12 11:35:14', '2026-10-12 11:35:20'),
(32, 7, 'e2dc536e9f382a0071a4236122791b869dc18b968270f1228d61d25c4a352940', '2026-10-12 19:35:25', '2026-10-12 11:35:25', '2026-10-12 12:48:21'),
(33, 1, '15b9e3f7519bd23f39bc585a621643eaa63ad78fe95843f003b77110b73e6edd', '2026-10-12 19:44:40', '2026-10-12 11:44:40', '2026-10-12 11:55:35'),
(34, 1, 'e480c856ba2f71dcca7cc83416234c1cb984ed83515bf0d4ae9faca03fb07e0a', '2026-10-12 19:54:32', '2026-10-12 11:54:32', NULL),
(35, 4, '80e252ccbcfd33dd2ae18c10e5eab7df1a1b02b28875c1b738303adc0cf0c861', '2026-10-12 19:55:45', '2026-10-12 11:55:45', '2026-10-12 11:55:59'),
(36, 8, 'a992e61b2b3e0de47994383154e75fd653ed3b4cceeec330932ee83e035e4d39', '2026-10-12 19:56:09', '2026-10-12 11:56:09', '2026-10-12 11:56:33'),
(37, 1, '5f5e76c74a7720112f3a546f9507aae84185101c4b849339ccd3c5c04d6f15a9', '2026-10-12 19:56:43', '2026-10-12 11:56:43', '2026-10-12 11:59:03'),
(38, 4, 'a579607b63783dbb7ad3802955692a9cf15d81f99edf32d906d1b10a8868ad50', '2026-10-12 19:59:12', '2026-10-12 11:59:12', '2026-10-12 12:02:15'),
(39, 1, 'f57e26522325487790654b01d9fc96942a915111001e933ce72f214458f31433', '2026-10-12 20:02:27', '2026-10-12 12:02:27', '2026-10-12 12:03:45'),
(40, 8, 'f43a9492a3727b7947c4b008d52a99676cc0bebdc0c12aba8dc779ac703759a6', '2026-10-12 20:04:02', '2026-10-12 12:04:02', '2026-10-12 12:04:27'),
(41, 7, '023b783774e4f0e441e0fc9f18e5c7782b57ff84a30a68358ebf00775b1cd2ee', '2026-10-12 20:04:33', '2026-10-12 12:04:33', '2026-10-12 12:33:47'),
(42, 1, '81b3016eaa2ed0f5beb8bc88ea4d990a050adb0de7da6e16bd59bc0bf605b246', '2026-10-12 20:33:52', '2026-10-12 12:33:52', '2026-10-12 12:44:47'),
(43, 8, '1c54fca0b80e262f383c0c3b631a4199110850bf233ee92c7b7f020faeb917d6', '2026-10-12 20:48:42', '2026-10-12 12:48:42', '2026-10-12 12:48:54'),
(44, 8, 'bf7f1f0b15c1f9f898192e289a35e8eeaed7735bf7161e2b2fc2693827b8294b', '2026-10-12 20:48:48', '2026-10-12 12:48:48', '2026-10-12 12:49:14'),
(45, 6, '9d389abc16df392243449f5ac03b13e1bb9ae264ea08bb4db0f9eed28128f471', '2026-10-12 20:48:58', '2026-10-12 12:48:58', '2026-10-12 12:49:01'),
(46, 1, '7530f6f003d20e43c340441c601391f9012eae6760f342e30d05d818b926c854', '2026-10-12 20:49:16', '2026-10-12 12:49:16', '2026-10-12 12:50:14'),
(47, 8, 'c1e2d96086609123f606a6552049c029b044efe7514ee9de41568d96c92a7071', '2026-10-12 20:50:03', '2026-10-12 12:50:03', '2026-10-12 13:15:24'),
(48, 8, 'e446e3d62c664cd418d7b217d48801e7b55de1a24fd123fa07cc0c4509bf2bbc', '2026-10-12 20:50:21', '2026-10-12 12:50:21', '2026-10-12 12:52:07'),
(49, 7, 'c699177f19ca61d3bb43bcc14874674831a019ad6f890c42b16815c08fe6140b', '2026-10-12 20:52:13', '2026-10-12 12:52:13', '2026-10-12 13:05:47'),
(50, 1, '5c002988cf39596276c5d9a62abd6be51b1ed3f92ba37107397629ac136a2a00', '2026-10-12 21:05:51', '2026-10-12 13:05:51', '2026-10-12 13:07:53'),
(51, 7, 'a9489471aa65614d7a9f3237f1dccc911627bbffd183c3e29ae026cf463d1148', '2026-10-12 21:07:58', '2026-10-12 13:07:58', '2026-10-12 13:09:38'),
(52, 1, '44e2a49d40050fa0b7fd768833afd9e5031334513256c1134b36225297804976', '2026-10-12 21:09:40', '2026-10-12 13:09:40', '2026-10-12 13:09:50'),
(53, 8, '4e40f4798b7cae322317dcd2f319f41a427a7a2439825929bf338047dfed8782', '2026-10-12 21:10:21', '2026-10-12 13:10:21', '2026-10-12 13:11:17'),
(54, 1, '67816566c8fd3c8ab71871adbc24211b63c47843c53fc5e496ef7211152b3012', '2026-10-12 21:11:40', '2026-10-12 13:11:40', '2026-10-12 16:00:59'),
(55, 1, 'fccd4dbe09b3a3a1612ad8113a3c663fab3f24f0677a2f94523b9bd2d6c4be40', '2026-10-12 21:15:29', '2026-10-12 13:15:29', '2026-10-12 13:38:39'),
(56, 8, '1036b157e9bf9fb97dfb28fc693fc9b9ee72c80e325544630d8589b908f08699', '2026-10-12 21:38:44', '2026-10-12 13:38:44', '2026-10-12 13:41:55'),
(57, 7, '356a0c2014848b73d662d1984ebc55911582ceafb290d1391c0a0841b45f915f', '2026-10-12 21:42:04', '2026-10-12 13:42:04', '2026-10-12 13:43:26'),
(58, 1, 'f29740c71d4b786beca16491ed2871210a3370063cd75471157e49e34ad728fa', '2026-10-12 21:43:31', '2026-10-12 13:43:31', '2026-10-12 13:46:04'),
(59, 7, '3a945abdc95ddd257a643df28fa77adca06e5746ecf78cd35a342356e67db387', '2026-10-12 21:46:12', '2026-10-12 13:46:12', '2026-10-12 13:46:49'),
(60, 1, '447b9bb4ed4c31bd95267de506571c58eea853187d907938d6f2fb5c9982a9fa', '2026-10-12 21:48:10', '2026-10-12 13:48:10', '2026-10-12 14:23:19'),
(61, 7, 'c744387ff8b3bae7e8eca30ba7475768f845e467708cec86602bb6ea51cc6914', '2026-10-12 22:23:32', '2026-10-12 14:23:32', '2026-10-12 14:23:36'),
(62, 7, '035c2c85fe905a537b5e314092865cc4f203499dce29b5d4b1d7b093b92ba0e9', '2026-10-12 22:23:44', '2026-10-12 14:23:44', '2026-10-12 15:16:51'),
(63, 7, '28d5026e942e744783bc22de89fb1af7b112603e8733ddcc468a5dd0ee3ea680', '2026-10-12 22:30:53', '2026-10-12 14:30:53', '2026-10-12 14:33:32'),
(64, 1, 'd05eaf5a32f9f5aacc7108c223f2cb3f5ba64bc4f2b3f04e7f742b2c85f758da', '2026-10-12 22:33:45', '2026-10-12 14:33:45', '2026-10-12 14:40:41'),
(65, 1, '34bb7f3daf1690c34173c1bf40478924433ce69d4f13ebcf4d5ca85e6e15865c', '2026-10-12 22:41:00', '2026-10-12 14:41:00', '2026-10-12 14:42:31'),
(66, 1, '5e1babf3cbbb064f638307f13de17298a13d4a172a1a96e1aa87722c6e642fe5', '2026-10-12 22:42:45', '2026-10-12 14:42:45', '2026-10-12 15:08:00'),
(67, 7, '61e735dde6c354f21a73fc69dbd829fefd0b7a44bc91fd9c8737c6bda4c0f2c1', '2026-10-12 23:08:14', '2026-10-12 15:08:14', '2026-10-12 15:40:24'),
(68, 1, '850841360bdc28f8f480f7ee1b42620b4aec42e48f9ae47e3824af1b9508d99e', '2026-10-12 23:40:35', '2026-10-12 15:40:35', '2026-10-12 17:01:00'),
(69, 1, 'ea1cabb7bae63b62e460960c0dffb7ba4e7ddb8eeb593ab2272e2acfc3337eed', '2026-10-12 23:42:30', '2026-10-12 15:42:30', '2026-10-12 15:43:01'),
(70, 5, '8905867d5f996e11fd73541f7d478536eff33d3c1a4f5acd550446436e5a0177', '2026-10-12 23:43:22', '2026-10-12 15:43:22', '2026-10-12 15:50:09'),
(71, 1, '80b129201c61d19294a0281c2b0d9f449f114b4ff38880fc1d107f2808a42677', '2026-10-12 23:44:27', '2026-10-12 15:44:27', '2026-10-12 15:51:12'),
(72, 1, 'bd172fb38da317efbababf5322ea434ba2de756d63698382269af8192b900a4e', '2026-10-12 23:50:17', '2026-10-12 15:50:17', '2026-10-12 15:54:16'),
(73, 1, '81afa8dd9117bbca7ec54b3fb07e97b578d5793a1f11ae01e1a6608fc7f72a7b', '2026-10-12 23:50:48', '2026-10-12 15:50:48', '2026-10-12 15:51:13'),
(74, 1, '436a5b3e80f7543a365a7cff866e433a7ef52ede54734285e5e09f8294efbd4b', '2026-10-12 23:51:35', '2026-10-12 15:51:35', '2026-10-12 15:56:22'),
(75, 1, '6d60329e64c942e67cd4a9b5cb46c63aec005203bbf6037c81ffad18cdb29569', '2026-10-12 23:56:37', '2026-10-12 15:56:37', NULL),
(76, 8, 'e9edda84470d736fc5ea9c14f4d0607499d2b92d40990663cb11718db89e6761', '2026-10-13 00:01:07', '2026-10-12 16:01:07', '2026-10-12 16:04:46'),
(77, 5, 'f521082ab4311c373e46a2a188da8f984c5502e9ceedf68bf9ea6ffbc68bb266', '2026-10-13 00:04:54', '2026-10-12 16:04:54', '2026-10-12 16:08:26'),
(78, 1, '8adfe0dc1858cae188e849e127b41a7bb033725ffd5a4bcc11f7492f26fe0483', '2026-10-13 00:07:00', '2026-10-12 16:07:00', '2026-10-12 16:09:35'),
(79, 1, '5c8be98b1313ef558714d63e7ace1ce8b39dfd4b489e55023063cf4c5950f59e', '2026-10-13 00:08:29', '2026-10-12 16:08:29', '2026-10-12 16:42:42'),
(80, 5, '0ffaa1dcb1b3f9ab2d9f115e0d20be8530a084ef99fac7c35877119b4ece43ce', '2026-10-13 00:10:01', '2026-10-12 16:10:01', NULL),
(81, 5, 'b428a41722d4d90319716cf62c2cf19443da2872539cb223cf32eed891123b2a', '2026-10-13 00:42:49', '2026-10-12 16:42:49', '2026-10-12 16:42:56'),
(82, 5, 'f183958b8be651ea3614fd253e85805f4e7e9f9ea01e1018083b6a40a524045b', '2026-10-13 00:43:29', '2026-10-12 16:43:29', '2026-10-12 16:59:09'),
(83, 1, '39f9f73efe9356c0c49c62f595f6f344c9e442fe5a6c278759b2fddccbb9c42f', '2026-10-13 00:59:45', '2026-10-12 16:59:45', NULL),
(84, 7, '40ee37f44e637c948447d8d773ad62f4076b113d2dc6336ba078cfe44a4c4230', '2026-10-13 01:01:12', '2026-10-12 17:01:12', '2026-10-12 17:01:40'),
(85, 1, 'b66a36d4665b0abe36d46b63210a2833150c9c351180d0117dcee946269ede60', '2026-10-13 01:02:05', '2026-10-12 17:02:05', '2026-10-12 19:14:30'),
(86, 1, '2a3cb88ba220b86bbef6dcb69c2a970a6e6ff03423d18c9feea5bb6c2bf326e6', '2026-10-13 02:01:05', '2026-10-12 18:01:05', '2026-10-12 18:14:16'),
(87, 1, '3ca9d597c32158c4d1bded2304bd14a680324841ee4925d309a6803b811c89a5', '2026-10-13 02:13:17', '2026-10-12 18:13:17', '2026-10-12 18:13:22'),
(88, 1, 'c160dc779f76eeee2101631fb5938ae207326b4dd53054b351788ed1b844cd6d', '2026-10-13 02:13:30', '2026-10-12 18:13:30', '2026-10-12 19:23:08'),
(89, 1, 'bac1066581f909683125934eaaad3825af9b9131022fd50d8afbf08910ea9d65', '2026-10-13 02:34:22', '2026-10-12 18:34:22', '2026-10-12 18:39:52'),
(90, 1, '4dff733811a32d0ff6c14d0f1aed72c2e7ab0ba44e55caf4a24a2acb2a8d670f', '2026-10-13 02:43:48', '2026-10-12 18:43:48', '2026-10-12 19:40:32'),
(91, 1, 'b21e16d2b1446e9042434c4dd093b9ee46d1eb10fb403ae602ed916b12dbb78a', '2026-10-13 03:14:39', '2026-10-12 19:14:39', '2026-10-12 19:17:05'),
(92, 1, '64994b51010ac57c4060bd2641195477f30836a598e80b4402c2224c65fbe964', '2026-10-13 03:20:02', '2026-10-12 19:20:02', '2026-10-12 19:20:19'),
(93, 1, '401fcc3ac05f7a6f319aca66fab73b08f354557a8ea6d293421ce2cc635c86cd', '2026-10-13 03:36:27', '2026-10-12 19:36:27', '2026-10-12 19:38:20'),
(94, 1, '9467e032d89d23aaaee8cb6bdc61c4ec2c48cc40f299f8a04e8e9dcd475b47e8', '2026-10-13 03:38:35', '2026-10-12 19:38:35', '2026-10-12 19:38:50'),
(95, 1, '89ead4a7434661715954336a0356d87eb497a95be34e9f4dc03b01f30bcf91f1', '2026-10-13 03:39:20', '2026-10-12 19:39:20', '2026-10-12 19:39:56'),
(96, 1, 'fa17cc7f39bc71dffe7231f5439156adb2fa7230bb7357fd8d83a8246a798e96', '2026-10-13 03:40:03', '2026-10-12 19:40:03', '2026-10-12 19:41:49'),
(97, 1, '89b18ecf1299045d9f1597750272b68718273918ece4d926cae800a3f43895c3', '2026-10-13 03:40:42', '2026-10-12 19:40:42', '2026-10-12 19:45:50'),
(98, 1, 'ea370f045db645c203b35ebd15cf0edefc61f0e4fa76f0ecee33d879ffd5beed', '2026-10-13 03:42:53', '2026-10-12 19:42:53', '2026-10-12 19:53:55'),
(99, 1, '20a58601522882ace8bdc89c7d7630271d36636bba41d64ca5d66e9eefeeca43', '2026-10-13 03:44:49', '2026-10-12 19:44:49', NULL),
(100, 1, 'bc404527b0efccbfc1bfa682bdcc0207576e71e992aca114c4a3537c26d1bf6c', '2026-10-13 03:46:05', '2026-10-12 19:46:05', '2026-10-12 19:54:14'),
(101, 1, 'd43f24ba234b0258ffce9525839d99eb31d24a02ecee12eacf662a12ec822375', '2026-10-13 03:54:13', '2026-10-12 19:54:13', '2026-10-12 19:54:15'),
(102, 1, '3b480bb25d55860c057e11a95ad988ea874e42081afeee701e647b3325bbe51e', '2026-10-13 03:54:45', '2026-10-12 19:54:45', NULL),
(103, 1, '1e727e0a5fe12ad793a1580696815cfeadb1183111e2efd7f14766f666072a2a', '2026-10-13 04:28:35', '2026-10-12 20:28:35', NULL),
(104, 1, '7030e26d33715f2dd1ac1573391418557866d4ef1700a86beca556a0a3756326', '2026-10-13 12:51:51', '2026-10-13 04:51:51', NULL),
(105, 1, '357e357aea6e0f85bd356d070d0dbfe587120e246dc6f4e4809b13fb5db3ff47', '2026-10-13 15:37:23', '2026-10-13 07:37:23', NULL),
(106, 1, '583ee323c8e8272b57ac1c34dcc26553caa43c1e10056dec0b1f4275e4736c99', '2026-10-13 16:33:43', '2026-10-13 08:33:43', NULL),
(107, 1, '0db4fb3a0bb34bf5598535f00728db8d196f514170fe9519ceede6d1545bff48', '2026-10-13 17:36:49', '2026-10-13 09:36:49', NULL),
(108, 1, 'ad0df8a2906937cbb9d457452737ebf591f4fd2c8f647a1fe52704c36bd37476', '2026-10-13 18:00:56', '2026-10-13 10:00:56', NULL),
(109, 1, 'f58b650a2a5362f94676d2873baa5a0890015e7664d7b30502300fda2463ef51', '2026-10-13 18:04:15', '2026-10-13 10:04:15', '2026-10-13 14:21:45'),
(110, 1, '6307e7c3a5ab244b2a9c3d232afa74581f89e16b4e6a736478721cce7afcb844', '2026-10-13 18:04:49', '2026-10-13 10:04:49', NULL),
(111, 1, '8b93b9c97827461d8afb3e2ad3aeffe16b1a04cf45ccaa3aeb0ee59d85c23e21', '2026-10-13 18:07:12', '2026-10-13 10:07:12', '2026-10-13 10:08:04'),
(112, 1, '22091c6c60b7c0a7abedfc85dddbbe1713271dee9251b77fce09dd975d4721ce', '2026-10-13 18:28:39', '2026-10-13 10:28:39', '2026-10-13 10:37:30'),
(113, 1, 'f8ff691ff501c2b8fc6d3ff7e2597e041d06030a8980d23fb61353b6503790df', '2026-10-13 18:40:26', '2026-10-13 10:40:26', '2026-10-13 10:40:47'),
(114, 6, 'cad50cc77f311cf03f883f0574cb6a40feaa75dc236df3cb1306781ed6ab533b', '2026-10-13 18:40:57', '2026-10-13 10:40:57', '2026-10-13 10:46:30'),
(115, 1, '9ddb2b9f66d57869c6c39447047f479a26ed59b10c9d98329e0157e0726477b0', '2026-10-13 18:46:39', '2026-10-13 10:46:39', '2026-10-13 10:48:52'),
(116, 7, 'e4e345f5c2bfcc9e7ce75edf5dc6b86399eb3bedbb35f59f488aaa57e7153aab', '2026-10-13 18:49:04', '2026-10-13 10:49:04', '2026-10-13 10:50:19'),
(117, 1, 'd66f990477f4b0541b6e2c2462fbd99c079e9c62bf21748af9c593da85021e7e', '2026-10-13 18:50:33', '2026-10-13 10:50:33', '2026-10-13 10:52:27'),
(118, 7, '8bdfbf13fe4fd407eb8d860c56618c07f60b49f254f6c5ab4cf4962ec9cd512e', '2026-10-13 18:52:39', '2026-10-13 10:52:39', '2026-10-13 10:54:03'),
(119, 1, 'ac04f6faf0391dfaf0e41ce2febc4bd0c04645b6b96b964455f9683ba4b5c983', '2026-10-13 18:56:08', '2026-10-13 10:56:08', '2026-10-13 13:09:22'),
(120, 1, '30a909ce282a58c8467ba5c761c111e675e046549a1e031344dc812239f802c0', '2026-10-13 20:53:22', '2026-10-13 12:53:22', '2026-10-13 12:54:30'),
(121, 1, '09af29609ca8e24a6bc2d9d23d654f93c0cc13b8abd65ee92ceefff5fbb7ba48', '2026-10-13 20:54:40', '2026-10-13 12:54:40', '2026-10-13 13:11:43'),
(122, 1, '7f5b900685b2406ebcf64352d04764aa00d61233a3b1d08b77781cb2a0c98ae2', '2026-10-13 21:09:33', '2026-10-13 13:09:33', '2026-10-13 14:23:22'),
(123, 1, 'bc5cb900015b2c7a46c22ae62b7e63e6017140e597c0d1dc36fd67544573928d', '2026-10-13 22:22:01', '2026-10-13 14:22:01', '2026-10-13 14:22:40'),
(124, 1, '554f31e8c63f704b43c76417dc1d98d98923d99e1b61cc8ff9c90386015ab14a', '2026-10-13 22:24:49', '2026-10-13 14:24:49', '2026-10-13 14:28:26'),
(125, 1, '0117ef75dd5573632ff1f6f30d9f0fbaed9ce1a63bc071da5319cd10592f3e2a', '2026-10-13 23:12:24', '2026-10-13 15:12:24', '2026-10-13 15:26:11'),
(126, 1, 'e3e6a0165c17685df6813ce06282cef50206d3993d54ca0ac51995a290c3352a', '2026-10-13 23:18:37', '2026-10-13 15:18:37', '2026-10-13 15:18:44'),
(127, 1, '05dd5fb9805c6d07745d99a9ec682130cf8e5b3b239276cd06ade105b320c9aa', '2026-10-13 23:19:07', '2026-10-13 15:19:07', '2026-10-13 15:19:14'),
(128, 1, 'd3113ced52037636ace4efde526d0a4ac2cb484551279e09525d11d89aced942', '2026-10-13 23:45:36', '2026-10-13 15:45:36', '2026-10-13 15:45:51'),
(129, 1, 'ee4479755a191dc9b8e2592e67f3009536cf0b80e87002cbfe3de02d23d8b9e7', '2026-10-13 23:56:37', '2026-10-13 15:56:37', '2026-10-13 15:56:42'),
(130, 1, 'cbaf5d8140c536657d39dcb2321bf537e2ff533e15fe37f5b32eab36e90a93c5', '2026-10-14 00:36:04', '2026-10-13 16:36:04', '2026-10-13 16:36:11'),
(131, 1, '81012e4b30abd7672f6f6ddf3ba94231d392779fe60761158a8f785710510f59', '2026-10-14 00:36:19', '2026-10-13 16:36:19', '2026-10-13 16:36:25'),
(132, 1, 'cc5a7875136f7321b107bdc71d582049771e996ff8a0ba750b93586120fb79fb', '2026-10-14 00:36:54', '2026-10-13 16:36:54', '2026-10-13 16:37:14'),
(133, 1, '3dfeab7b2a5514b85aa48a4c4742c5c3b983dee53c119d591c4537cc8a431ea0', '2026-10-14 00:37:23', '2026-10-13 16:37:23', '2026-10-13 16:37:51'),
(134, 1, 'dc322031f31fcda9496d60db7d503c4c853ec8b0cf1ee3e6fbcfafec50c72066', '2026-10-14 00:37:59', '2026-10-13 16:37:59', '2026-10-13 16:38:56'),
(135, 1, '3ae9960b0016721b640910890876843848f173e9425e46fa3823666888780599', '2026-10-14 00:39:32', '2026-10-13 16:39:32', '2026-10-13 16:42:56'),
(136, 1, '591af65ecc06a2a94447ae40f84c32797f688e4a48edd948103a62734072354a', '2026-10-14 00:43:03', '2026-10-13 16:43:03', '2026-10-13 16:43:08'),
(137, 1, '7e2fb573017ab95d92d0781f3178239909dbfc7c246aa782f453e8c1868c336f', '2026-10-14 00:43:18', '2026-10-13 16:43:18', '2026-10-13 16:44:04'),
(138, 1, 'ef8a0400da815f9a2b3ac2af091b2fd3a00141b0346dc5f3d82414744c405c1b', '2026-10-14 00:44:16', '2026-10-13 16:44:16', '2026-10-13 16:45:45'),
(139, 1, 'bb5ca3989d369575486dd65e11ce88402afe334679cd876ce06f67d3d60b6dc0', '2026-10-14 00:45:54', '2026-10-13 16:45:54', '2026-10-13 16:46:30'),
(140, 1, 'e3f9c73b3c236a1abe0633fa06e58642ccbf0a6f097fae7aaca737a46e8a5a0e', '2026-10-14 00:46:38', '2026-10-13 16:46:38', NULL),
(141, 1, 'a3152c918f0dd2b7f4e422c338a17dfc97865d60baa217545bda872baca73bc7', '2026-10-14 00:48:21', '2026-10-13 16:48:21', NULL),
(142, 1, 'ea42463b62d4ebd30c02c8f12fe18f67bd610d0978071597a7cff48550fe1b0b', '2026-10-14 14:37:51', '2026-10-14 06:37:51', '2026-10-14 06:43:53'),
(143, 5, '36f5bd97bacfb306154f9f870b7f93fa88ffc7c27d3903fa27b22c5803034405', '2026-10-14 14:44:11', '2026-10-14 06:44:11', '2026-10-14 07:03:34'),
(144, 1, '28abcd90392ed091d8811d8b3862fc9763931d1796ccee4a0f3e13b8e5ab175f', '2026-10-14 15:03:50', '2026-10-14 07:03:50', '2026-10-14 07:25:28'),
(145, 1, 'c3198c98ffa02c31aa9c251e230bc8eeac07901f6a764b286202971c234a5555', '2026-10-14 15:25:56', '2026-10-14 07:25:56', '2026-10-14 07:28:03'),
(146, 1, '84623b1d963fd1cb0c7109399269cd27a1c805d1b429d91f51866c3502494df8', '2026-10-14 15:28:08', '2026-10-14 07:28:08', '2026-10-14 08:19:01'),
(147, 7, 'c193494faf2fffe4b5b877ad1fd4bd54ca1209be38cf2e566c77f4f3be1be304', '2026-10-14 16:19:32', '2026-10-14 08:19:32', '2026-10-14 08:21:45'),
(148, 1, '5c1e0e22d70a5f96a00044de4207fc1d42622ff60e11a888e0b3b6d3fba42a05', '2026-10-14 16:21:50', '2026-10-14 08:21:50', '2026-10-14 08:25:51'),
(149, 7, '73e1ac471dc0d638b890f56b1ddc81cf0d2776913d7ad8b879d5e6ca64847a3c', '2026-10-14 16:25:58', '2026-10-14 08:25:58', '2026-10-14 08:26:44'),
(150, 1, 'dff1e365d01853abc898d1c61e5a06f7d7eb6abece597e36e2abfb79484fb309', '2026-10-14 16:26:49', '2026-10-14 08:26:49', '2026-10-14 08:27:32'),
(151, 7, '84bf3a8dfa36012169b1a7791bbe56b1769cd292596d330f818cf3c91c2c7342', '2026-10-14 16:27:37', '2026-10-14 08:27:37', '2026-10-14 08:27:52'),
(152, 1, '7fd0c26e43c2ff05aa5e4375e4f8c40d6f3c5a52e93670dbd12ee839b0796aec', '2026-10-14 16:28:00', '2026-10-14 08:28:00', '2026-10-14 08:28:55'),
(153, 9, '10c6a043d909781924d6f618d5f6a5227e18f504e77c3e4a9f19ad8491d27d97', '2026-10-14 16:28:58', '2026-10-14 08:28:58', '2026-10-14 08:29:29'),
(154, 1, 'e0fbe7594d08b8746d1c8c11b8e08f04346ef3e09ab344a1f2f0af6e26093434', '2026-10-14 16:30:05', '2026-10-14 08:30:05', '2026-10-14 08:31:17'),
(155, 7, '8e8a7dbc033b1bce126416507f15a7dff60d8a8b3294dec4f268530cd68a8c35', '2026-10-14 16:31:31', '2026-10-14 08:31:31', '2026-10-14 08:50:05'),
(156, 1, '36b6aa55d878136da0294939e431009547c08eb0463755c7ef101e83dbcd7254', '2026-10-14 16:31:38', '2026-10-14 08:31:38', '2026-10-14 08:31:55'),
(157, 10, '1ec140d6b8f0a8e6f15893497904fa1955ec8249f0af744d1acfc50e27096fd5', '2026-10-14 16:32:10', '2026-10-14 08:32:10', '2026-10-14 08:32:48'),
(158, 1, 'ff9244f10ab0bc1a098e22c32b75cb34977f87c4bce0f3e38ac1e96e95d49699', '2026-10-14 16:32:53', '2026-10-14 08:32:53', '2026-10-14 08:34:17'),
(159, 3, '59702e021d8d8fac30ea30b07cdc7fb3f95e24515b66ec63f6312b3c8fa2f98c', '2026-10-14 16:34:22', '2026-10-14 08:34:22', '2026-10-14 08:36:53'),
(160, 10, '6b46b84f9b12b1188367d444117d3be2fb488ff4f2a3421cbdb9632254ee59d0', '2026-10-14 16:38:53', '2026-10-14 08:38:53', '2026-10-14 08:39:27'),
(161, 1, 'e0a826233278643774088a90b85a6a1b2b03d420535d0b9a2c6ef601c5924f6a', '2026-10-14 16:39:31', '2026-10-14 08:39:31', '2026-10-14 08:48:19'),
(162, 9, '14ad2914ae2ee877514b3e3a917f2759f8b400084017fa4c19487148e7655b60', '2026-10-14 16:48:24', '2026-10-14 08:48:24', '2026-10-14 08:49:50'),
(163, 1, '53819279fe80993e37fabb82335a9b3f78f2a19d3a0aedba3ba047887f6da492', '2026-10-14 16:50:01', '2026-10-14 08:50:01', '2026-10-14 08:53:44'),
(164, 10, '05faefe88a88f567cd97c8f7ba995612514e3b831786343ab1482c6ab737a475', '2026-10-14 16:53:51', '2026-10-14 08:53:51', '2026-10-14 08:54:45'),
(165, 1, '975c1338cf732372808ecda83070e153c645e8d7c698b6896eb7638569996f4f', '2026-10-14 16:54:49', '2026-10-14 08:54:49', '2026-10-14 08:59:17'),
(166, 7, 'c32b140c1791d8d14da59c6ce5ffcd3b38006eb7ae7fdc8ff0c926599edd08ab', '2026-10-14 16:55:01', '2026-10-14 08:55:01', '2026-10-14 08:55:07'),
(167, 7, '72902fda45970a2232111ba962e34e0aa8914bd73a13491c6693a56f8b91192c', '2026-10-14 16:58:50', '2026-10-14 08:58:50', '2026-10-14 08:58:54'),
(168, 1, 'ecb47afa4ba8b99e67e680e736c15e7494b0f180e1cd2ff5ed3727b920d32f3e', '2026-10-14 16:59:23', '2026-10-14 08:59:23', '2026-10-14 08:59:56'),
(169, 10, '021fa9528eee185f9fd489d886dde3af8fdb017eaf41dbc7fa349e072084fb85', '2026-10-14 17:00:02', '2026-10-14 09:00:02', '2026-10-14 09:02:23'),
(170, 1, 'f0720df7aa7e7f0a6f7bb29bc367641566120e79f42a18dc85f3bc89f3192599', '2026-10-14 17:02:28', '2026-10-14 09:02:28', '2026-10-14 09:35:18'),
(171, 1, 'bec3805128a4580f7f582b6b500a0bf123782d7f67c877ca72c44ffcadf4aa99', '2026-10-14 17:31:51', '2026-10-14 09:31:51', '2026-10-14 09:32:13'),
(172, 9, '4aa35062508084da5ae4751209da011a972ff25a01eb381e8457059c056368b0', '2026-10-14 17:32:20', '2026-10-14 09:32:20', '2026-10-14 09:32:57'),
(173, 1, 'f8b9315bce0dffb46b145a1988f8fd236230fa6b38bf9c522715eed54668b980', '2026-10-14 17:33:01', '2026-10-14 09:33:01', '2026-10-14 10:14:12'),
(174, 7, '89cf0d9d8c81c9fa9736550d2e356718871c616e7173f809b7ea64a35616eb6d', '2026-10-14 17:35:51', '2026-10-14 09:35:51', '2026-10-14 09:36:02'),
(175, 5, '98e11ab13b75fe90bf6007dc8b4470b63868a35b8db23f15dbce12addd657cf6', '2026-10-14 17:37:19', '2026-10-14 09:37:19', '2026-10-14 09:38:43'),
(176, 1, '3538907a616a6336c8c02cb133d6b0173541f5c2529ba55eb935509b034060e9', '2026-10-14 17:38:47', '2026-10-14 09:38:47', '2026-10-14 09:41:24'),
(177, 10, 'a3a8e16ebe6a0812c8b8ba3f5d096e4b0bd6ddf40d1c00afbf65b9d7d4dca318', '2026-10-14 17:41:34', '2026-10-14 09:41:34', '2026-10-14 09:47:23'),
(178, 7, '54d810cb5b33d8f1e5c95a10e23d0e5af4bd52faaeb64449ff6daea38705b570', '2026-10-14 17:47:22', '2026-10-14 09:47:22', '2026-10-14 09:47:35'),
(179, 1, 'cc2f2842693eb1838206b8a4caea2b0125e6758db0921eada256d10aa477a8f7', '2026-10-14 17:47:27', '2026-10-14 09:47:27', '2026-10-14 10:16:25'),
(180, 7, '3030e2b404ad15008f14b925187daab2ee834ecdece87797353fc2424f74c88b', '2026-10-14 17:53:39', '2026-10-14 09:53:39', '2026-10-14 09:53:44'),
(181, 7, '3d457d3e5b75544d442a461e594639bebc2d1ecb49ac92d640de826354d507ab', '2026-10-14 17:54:02', '2026-10-14 09:54:02', '2026-10-14 09:54:09'),
(182, 7, '64bbf3be4e42c140ecce9c11cc4e715c853b92d8f0414184ea07cb32ce9156bb', '2026-10-14 17:56:51', '2026-10-14 09:56:51', '2026-10-14 09:57:49'),
(183, 7, 'e453fe8d833a4a2d6548c87ad59d922cc0dee065af490851335221e131b45617', '2026-10-14 17:58:08', '2026-10-14 09:58:08', '2026-10-14 09:58:20'),
(184, 7, '6e6cd564efb07ad81136c64b9efc496a5c204dd1d760ba49b7794f1ac72843bd', '2026-10-14 17:58:46', '2026-10-14 09:58:46', '2026-10-14 09:58:52'),
(185, 7, '4f056f23d4291461fd4a0e6f6a26b4c9501873e6addd44d057013fb63fc5d024', '2026-10-14 18:08:14', '2026-10-14 10:08:14', '2026-10-14 10:08:20'),
(186, 7, '502a4fe5d9767d4e0fcf9122a51e52fb5051110b8e2d9fe7fb6a5f6022e146ad', '2026-10-14 18:08:55', '2026-10-14 10:08:55', '2026-10-14 10:09:00'),
(187, 7, 'b2fb647b4e393cca6b24a04fa038b65cfc985378cd77375f08adde9e4e706cdd', '2026-10-14 18:10:35', '2026-10-14 10:10:35', '2026-10-14 10:10:40'),
(188, 7, 'a075b85a08067adc43c027ccc5ccd7aacc24310e6f903961a63c06b52bc779e0', '2026-10-14 18:13:11', '2026-10-14 10:13:11', '2026-10-14 10:13:14'),
(189, 7, 'e72c8748bc8c8668742066186bf217b8e27f11cc46333071757f81ebebd6416c', '2026-10-14 18:13:29', '2026-10-14 10:13:29', '2026-10-14 10:13:34'),
(190, 7, 'e17b56ad13d8d659be20edc332cd7ea623e40ab450d888a501ec6ef471d71335', '2026-10-14 18:13:45', '2026-10-14 10:13:45', '2026-10-14 10:13:49'),
(191, 7, '2f60e9358f2512ee682b2e7601187d0c8b8d17f3020586e22b00d9da6a7ed424', '2026-10-14 18:14:19', '2026-10-14 10:14:19', '2026-10-14 10:14:23'),
(192, 7, 'a2bd7b1de8be72e780ec056215cbf433dda662b7cb7f73dfcd8d92fd9e29cc5e', '2026-10-14 18:14:40', '2026-10-14 10:14:40', '2026-10-14 10:14:44'),
(193, 10, 'f71088a4fabef55818eb65787f2b7f8aaf4c095fd1b05376b6e1461c00d7a074', '2026-10-14 18:16:31', '2026-10-14 10:16:31', '2026-10-14 10:17:57'),
(194, 1, '0f9efbc0014bdff75ac57d11b507a440036c1443e31ead54d132794c39bda74c', '2026-10-14 18:18:05', '2026-10-14 10:18:05', '2026-10-14 10:25:57'),
(195, 10, 'd836e4a18cbb16f55c3d940db7f5cfd05d45d1ec264a969dec4e9a0560eee8b1', '2026-10-14 18:26:08', '2026-10-14 10:26:08', '2026-10-14 10:37:24'),
(196, 1, '54f735e79939c0abdbdba6da7fabc7a12668e6b1195fb09a31a37f7a2c1c743c', '2026-10-14 18:30:35', '2026-10-14 10:30:35', '2026-10-14 10:53:02'),
(197, 1, '3e0742007684b26f9f9bbded2cd76bd04040523cbe2de57dbde9fc22de105035', '2026-10-14 18:37:29', '2026-10-14 10:37:29', '2026-10-14 10:41:44'),
(198, 10, '824ff9b3d061da5c915ae972b1265ee42837aad342cb546f6ca098cbb3c79b47', '2026-10-14 18:41:52', '2026-10-14 10:41:52', '2026-10-14 10:50:27'),
(199, 1, '906c1c1fb0828f64d1a469ec114f34f5378307ee7fb1f7ea9fda4c49f092bd5b', '2026-10-14 18:50:32', '2026-10-14 10:50:32', '2026-10-14 10:51:15'),
(200, 11, '89df7c4c4fa9cf934dcf85078ddb963bc21bc79b1ee020b656154ccbd51916cc', '2026-10-14 18:51:20', '2026-10-14 10:51:20', '2026-10-14 11:03:06'),
(201, 10, 'ac9ddf32c059c529fb3b4602033f832163e60022a2fabab4bb398e04d5687cbf', '2026-10-14 18:53:21', '2026-10-14 10:53:21', '2026-10-14 10:55:01'),
(202, 1, 'ebd5103a7355077129d6aa74fce269cbe70a589d8c73ad6ef449688064d2eadc', '2026-10-14 18:55:04', '2026-10-14 10:55:04', '2026-10-14 11:47:42'),
(203, 7, '8b0e2e33bd33bf640610ee025e4d84951eba9a1e371421cdeb85bd6c45b53419', '2026-10-14 19:03:01', '2026-10-14 11:03:01', '2026-10-14 11:03:40'),
(204, 1, '03060396733b169e0cff96ae91a85380bddd2e7cd14c0ab21c8bf9b3d6227873', '2026-10-14 19:03:26', '2026-10-14 11:03:26', '2026-10-14 11:10:05'),
(205, 3, '2642d2e0451e02d20458e845fed7d5fe4ebf38b4b4b497e7066bfae586060167', '2026-10-14 19:10:14', '2026-10-14 11:10:14', '2026-10-14 11:10:46'),
(206, 1, '446ff27873d5aa60a0e3ef476b5b704b1a2e948569b7c43842727114c9efff50', '2026-10-14 19:10:59', '2026-10-14 11:10:59', '2026-10-14 11:11:38'),
(207, 10, '3b54bc023921416664527f6321b7c90ee9a7491800a54c2009dd5e1cf6811df7', '2026-10-14 19:11:42', '2026-10-14 11:11:42', '2026-10-14 11:12:49'),
(208, 1, 'c8d54f185ed70ec38486548ff180b7c1d72c7d3a71b77c947555da20c32dbd9b', '2026-10-14 19:12:54', '2026-10-14 11:12:54', '2026-10-14 11:14:02'),
(209, 1, '003c69e9929f4be754719168ddc48bee427fa2b04f582bd15226a8ac04219b4a', '2026-10-14 19:14:15', '2026-10-14 11:14:15', '2026-10-14 11:14:52'),
(210, 7, 'abc6288ac0bf7c1efd0c7512093f2f580232e500f259033147e1557ba9c1f15f', '2026-10-14 19:14:23', '2026-10-14 11:14:23', '2026-10-14 11:14:27'),
(211, 7, 'e10497f6ee29fb188096f51120d9aaafb3a277c5f27b5879698df14c12e9033b', '2026-10-14 19:14:58', '2026-10-14 11:14:58', '2026-10-14 11:36:47'),
(212, 1, 'd06d6192d6f73b057582ac7ce0dd2ecd8a5f953536561fe5881bad9222d00da5', '2026-10-14 19:15:06', '2026-10-14 11:15:06', '2026-10-14 11:36:39'),
(213, 7, '4f968a2b6cf9a1d111418091bf52e670cfbbe532850afcbc99c4a4d33f2caeab', '2026-10-14 19:39:33', '2026-10-14 11:39:33', '2026-10-14 11:39:41'),
(214, 1, 'a13a2f2c7b71fcde50a92af2c9048db4dd2cd328bc5df6a162f489923d7153fa', '2026-10-14 19:39:35', '2026-10-14 11:39:35', '2026-10-14 11:55:32'),
(215, 1, 'd2950685e6b762a297fec6660c423fe7b0cf8928195f45af336fc1f17f9ee950', '2026-10-14 19:47:46', '2026-10-14 11:47:46', '2026-10-14 11:49:06'),
(216, 7, 'e67bdfe52cf067b3d51281a07ba9b6ab5982d10db9aed0877b5f596ea73b204d', '2026-10-14 19:49:31', '2026-10-14 11:49:31', '2026-10-14 12:46:49'),
(217, 10, '3eab978f136374d0b179724e8d187efbfd907c37dafc575be6a30ba2f0f966b1', '2026-10-14 19:55:41', '2026-10-14 11:55:41', '2026-10-14 12:27:59'),
(218, 1, 'd07ceb5c92eab8f7baabc2202ca2f0106b03df1b03085792082ded8b92ab66ed', '2026-10-14 20:28:04', '2026-10-14 12:28:04', '2026-10-14 12:30:47'),
(219, 5, 'dacbd6a96f5f745c0b9801183a2eb14b766f1fee41b60d0eb0c7d7e5eccddbd6', '2026-10-14 20:30:52', '2026-10-14 12:30:52', '2026-10-14 12:39:56'),
(220, 1, '9657234ab8f947b38ce35d86f495c946563ee84841c1b87bd9f4171ecb1ad132', '2026-10-14 20:40:09', '2026-10-14 12:40:09', '2026-10-14 12:40:44'),
(221, 7, 'f644a77a92f0dcdf7e955182772da4341c6f37d99846971fc308417031b57269', '2026-10-14 20:41:02', '2026-10-14 12:41:02', '2026-10-14 12:41:41'),
(222, 1, '25d3ce7dc93594ffbdaae6698c549ff2c683f5b95b80989044dacb16d230caec', '2026-10-14 20:41:14', '2026-10-14 12:41:14', '2026-10-14 12:48:18'),
(223, 7, '031b73635d2ffc92b0b2618c2d6306d1f14d3fea208601357b70a0a455aa0fb7', '2026-10-14 20:42:19', '2026-10-14 12:42:19', '2026-10-14 12:42:21'),
(224, 7, '3b2638ccc8e4745078cf8fdd0345978a6633d99a5da41e5cf3c2b23c33a0f70e', '2026-10-14 20:42:41', '2026-10-14 12:42:41', '2026-10-14 13:01:49'),
(225, 1, 'e9b23a20be50a16289f678d193875188e9d278dccb91979b6d6bb9d041efb080', '2026-10-14 20:46:12', '2026-10-14 12:46:12', '2026-10-14 12:47:47'),
(226, 1, '4a2f56da51bcc012aa95389f895cab3865f971b6ebef4840ed1f809e0c3c383e', '2026-10-14 20:46:54', '2026-10-14 12:46:54', '2026-10-14 14:13:22'),
(227, 1, 'ae5c3a7d869535534305c9b3b33bfd8a50cff592bd28fbb538619c28a2c59f9a', '2026-10-14 20:48:26', '2026-10-14 12:48:26', '2026-10-14 12:48:33'),
(228, 6, '8ff8d33229d7ff5f0c908e2530d9ed9dcf113ed3e54eea2049579fe3fe550134', '2026-10-14 20:48:37', '2026-10-14 12:48:37', '2026-10-14 12:49:40'),
(229, 5, '28901656abe4d71137980e6c787ec63aa0a26a4235fef5222ac95b7d80ba15e8', '2026-10-14 20:49:46', '2026-10-14 12:49:46', '2026-10-14 12:49:55'),
(230, 3, '276d86277964b6c3da3297936335dfa5162dc095869c69e2a7ffd2e01b2a0981', '2026-10-14 20:50:00', '2026-10-14 12:50:00', '2026-10-14 14:23:31'),
(231, 3, '5b8cd979e40a1bcae4450e001cf6e2a9f0349e7ecf3a4471c78890be468e51eb', '2026-10-14 21:01:55', '2026-10-14 13:01:55', '2026-10-14 13:02:16'),
(232, 1, 'db689e97c93dd9b7912da169c107a930684bf009a0b9f4f4076c030e5e6bc22d', '2026-10-14 21:02:23', '2026-10-14 13:02:23', '2026-10-14 13:02:24'),
(233, 3, 'c133bcbd27fe96fc3396a808eea7f5b0eaea9ff718215507327b55b11aa69854', '2026-10-14 21:03:13', '2026-10-14 13:03:13', '2026-10-14 13:04:36'),
(234, 3, '984a29878e3fba22c9ae77f8bc96c1c5d8d1408812473e6d2a499ac5f3d092f7', '2026-10-14 21:04:47', '2026-10-14 13:04:47', '2026-10-14 13:07:25'),
(235, 3, '0bd7b8383abb81264ebb979cb149f77438821f3b4880f5ac14dcc42a1b13b2d4', '2026-10-14 21:07:41', '2026-10-14 13:07:41', '2026-10-14 13:10:36'),
(236, 3, '41a9d1d1d9d1d6ed61729b06f5a7416d8075b6a351269875cf9ceb78a1bbbfa1', '2026-10-14 21:10:41', '2026-10-14 13:10:41', '2026-10-14 14:11:05'),
(237, 1, '609b9274e9f0ee17980b733fe2f03666cbdc8fedd17feab5a6d239914757485f', '2026-10-14 22:11:16', '2026-10-14 14:11:16', '2026-10-14 14:15:03'),
(238, 1, '8362b7afa868e80e4191efe34faea8033b02d5155bdd6193b507ed1700274b08', '2026-10-14 22:13:25', '2026-10-14 14:13:25', '2026-10-14 15:14:02'),
(239, 7, '1a846466f3c423e96f05847cad3bb8577c5cf13885a60e5f129c463f3b0692f1', '2026-10-14 22:15:09', '2026-10-14 14:15:09', '2026-10-14 14:41:33'),
(240, 5, '5974f7967d5261556a07bc276d54cf8a8ede193a8ac6e29b2cc8e294331a5d19', '2026-10-14 22:35:07', '2026-10-14 14:35:07', '2026-10-14 14:42:27'),
(241, 1, 'fe59f6f6d2c3d8479683a51d25983599e30d58baeeed508485b1992e78eef2e2', '2026-10-14 22:41:46', '2026-10-14 14:41:46', '2026-10-14 14:43:00'),
(242, 5, '60cdb19d742b1899ff274ab3a478dfe21affa34235451d20726f8d43a6eef816', '2026-10-14 22:43:11', '2026-10-14 14:43:11', '2026-10-14 14:47:52'),
(243, 1, '0fad303d8d66a77dffb7f3a527f4f80d219746fe98e12a77da2af6a6960c8b96', '2026-10-14 22:48:00', '2026-10-14 14:48:00', '2026-10-14 15:44:04'),
(244, 1, 'a7265991bebde6c7c7f836f01097c47ef0907c1794de4dcefcf62a9b4f826fd5', '2026-10-14 22:55:24', '2026-10-14 14:55:24', '2026-10-14 14:57:57'),
(245, 1, '8b60edaa60c8d8c9296d8a66c45b059c514eded714861f3ca45414bbbc352cca', '2026-10-14 22:56:08', '2026-10-14 14:56:08', '2026-10-14 15:15:50'),
(246, 7, '0f68fc74cb5f372057a9c94c106b5a54c3fbc75b12ffd7dc82b921a96d6274bf', '2026-10-14 23:14:08', '2026-10-14 15:14:08', '2026-10-14 15:14:32'),
(247, 1, '0612b1159021c76eaae953bc582a415619218049158dedf8ba7837910ac3d3ca', '2026-10-14 23:16:13', '2026-10-14 15:16:13', NULL),
(248, 1, 'b780e191e55173cd9c0175c5a6c6269861eae9e9ab12fa4cab934b86170b84c7', '2026-10-14 23:45:53', '2026-10-14 15:45:53', '2026-10-14 15:45:56'),
(249, 1, 'ff7e052d7952e93f0216185234f5137d3fd6bec5c3e6cd2f4798e04eec43da6d', '2026-10-14 23:46:07', '2026-10-14 15:46:07', '2026-10-14 15:46:10'),
(250, 1, 'facf07cd78e6ef7e684e11eb2868bc55cfaa0f3b8a63ab1df74ed77ab93d9583', '2026-10-14 23:46:46', '2026-10-14 15:46:46', '2026-10-14 15:46:50'),
(251, 1, 'ce56a509b34e43e47336a37e7ed40e542b4ee24e502dbaaf1b951af5e7dcfb7c', '2026-10-14 23:56:22', '2026-10-14 15:56:22', '2026-10-14 15:56:55'),
(252, 1, '7cf1e8ddddb4afcb7cadaa3a50f02f9b878986f7a58d47345de8934e6726e80d', '2026-10-15 04:13:10', '2026-10-14 20:13:10', '2026-10-14 20:14:30'),
(253, 1, 'f77755ad53e1aaee4473f15dc97165d70ee6e194892c0ec8ee660ac55b0cd7c4', '2026-10-15 14:30:06', '2026-10-15 06:30:06', '2026-10-15 06:32:40'),
(254, 1, '77aca1e94a40de6ba147e8fbdb4e876110d19c07ac1e4c7495bdec6c01c4d3c1', '2026-10-15 15:08:25', '2026-10-15 07:08:25', '2026-10-15 07:09:22');

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
  ADD KEY `idx_organization_status` (`status`),
  ADD KEY `idx_organizations_created_by` (`created_by`),
  ADD KEY `idx_organizations_updated_by` (`updated_by`);

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
  ADD KEY `idx_users_name` (`last_name`,`first_name`),
  ADD KEY `idx_users_created_by` (`created_by`),
  ADD KEY `idx_users_updated_by` (`updated_by`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `concern_comments`
--
ALTER TABLE `concern_comments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `concern_status_attachments`
--
ALTER TABLE `concern_status_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `concern_status_history`
--
ALTER TABLE `concern_status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `concern_types`
--
ALTER TABLE `concern_types`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `organizations`
--
ALTER TABLE `organizations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=255;

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
-- Constraints for table `organizations`
--
ALTER TABLE `organizations`
  ADD CONSTRAINT `fk_organizations_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_organizations_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_users_organization` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_users_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD CONSTRAINT `fk_sessions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
