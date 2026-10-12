-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 12, 2026 at 09:18 AM
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
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `organizations`
--

INSERT INTO `organizations` (`id`, `name`, `organization_type`, `description`, `contact_email`, `contact_number`, `address`, `status`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'IT Department', 'admin_facilities', 'Information Technology Department', NULL, NULL, 'UG Alfresco Building A', 'active', '2026-10-01 21:22:29', '2026-10-12 13:41:32', NULL),
(2, 'VXI', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale Building A', 'active', '2026-10-02 11:44:39', '2026-10-12 13:41:32', NULL),
(3, 'Engineering Department', 'admin_facilities', 'Felcris Centrale Engineering Team', NULL, NULL, 'Felcris Centrale UG Parking', 'active', '2026-10-02 14:09:36', '2026-10-12 13:41:32', NULL),
(4, 'Optum', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:19:29', '2026-10-12 13:41:32', NULL),
(5, 'TelePerformance', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:20:30', '2026-10-12 13:41:32', NULL),
(6, 'IBEX', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:20:55', '2026-10-12 13:41:32', NULL),
(7, 'Regus', 'tenant', NULL, NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:21:43', '2026-10-09 15:21:43', NULL),
(8, 'Intellicare', 'bpo', 'BPO Company', NULL, NULL, 'Felcris Centrale', 'active', '2026-10-09 15:22:16', '2026-10-12 13:41:32', NULL);

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
(1, 'superadmin', '$2b$12$7Q2BZNGJ8VG8/aX288L7zextU/UWOthz0MWQarPSPUik6UwaYlnXK', 'System', NULL, 'Administrator', 1, NULL, '/uploads/users/0f5206e8-6c0d-46cc-9b3f-a59d4ee8e31c.png', 'active', '2026-10-12 14:42:45', '2026-10-01 21:22:29', '2026-10-12 14:42:45', NULL),
(3, 'Robert', '$2b$12$8SKS9bJXjVx4Mdjk07Cj/eq.r0eq32ciklk0NClL7a0U5FoR33SNW', 'Robert', NULL, 'Cabungcag', 2, 3, NULL, 'active', '2026-10-12 11:25:24', '2026-10-03 21:36:12', '2026-10-12 11:25:24', NULL),
(4, 'VXI', '$2b$12$a2B3ATk3m2JvGo6mc/HiLOdSCRLp8vgUnWj.9FMUcmY1cIvm/Ymyq', 'VXI', NULL, 'BPO', 2, 2, NULL, 'active', '2026-10-12 11:59:12', '2026-10-03 21:46:59', '2026-10-12 11:59:12', NULL),
(5, 'BAO', '$2b$12$54wpUtxpdJFt/GkPVsp4keSo9fO1Ufws7wDboouXj3PBoUChAmmhe', 'BAO', NULL, 'Engineering', 2, 3, NULL, 'active', '2026-10-12 11:10:21', '2026-10-03 21:48:33', '2026-10-12 11:20:45', NULL),
(6, 'sample', '$2b$12$p7PWE8B6Awwdjx5zob.sRuv/xW6Yly/ErTIouWyUoZKO/rK131LaC', 'sample', NULL, 'user', 3, 3, NULL, 'active', '2026-10-12 12:48:58', '2026-10-04 22:13:40', '2026-10-12 12:48:58', NULL),
(7, 'Ibex', '$2b$12$bwT9UW78tZcR8TjFsMYvcegv7SfnZ2wSEDxD5N0nFR75WNq0Rk.zC', 'Ibex', NULL, 'BPO', 2, 6, NULL, 'active', '2026-10-12 15:08:14', '2026-10-12 10:55:39', '2026-10-12 15:08:14', NULL),
(8, 'John Lyndon', '$2b$12$ykmq8wpKlpypifL8jQRnw.Q7S.Ikqn5pfOJLu9H9S3w1WPy94/6Xa', 'John Lyndon', NULL, 'Sinajon', 2, 3, NULL, 'active', '2026-10-12 13:38:44', '2026-10-12 11:24:28', '2026-10-12 13:38:44', NULL);

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
(54, 1, '67816566c8fd3c8ab71871adbc24211b63c47843c53fc5e496ef7211152b3012', '2026-10-12 21:11:40', '2026-10-12 13:11:40', NULL),
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
(67, 7, '61e735dde6c354f21a73fc69dbd829fefd0b7a44bc91fd9c8737c6bda4c0f2c1', '2026-10-12 23:08:14', '2026-10-12 15:08:14', NULL);

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=68;

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
