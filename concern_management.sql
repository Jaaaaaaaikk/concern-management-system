-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 05, 2026 at 05:27 AM
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
  `acknowledged_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `resolved_at` datetime DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `concerns`
--

INSERT INTO `concerns` (`id`, `concern_number`, `title`, `description`, `concern_type_id`, `created_by`, `assigned_organization_id`, `status`, `priority`, `created_at`, `acknowledged_at`, `updated_at`, `resolved_at`, `closed_at`) VALUES
(1, 'CON-2026-00001', 'pipe', 'the pipe was leaking at UG alfresco restroom', 3, 2, 3, 'closed', 'high', '2026-10-03 21:37:36', '2026-10-03 21:49:10', '2026-10-04 09:33:38', '2026-10-04 08:16:00', '2026-10-04 08:16:47'),
(2, 'CON-2026-00002', 'tiles', 'the tiles cracked', 3, 2, 3, 'closed', 'urgent', '2026-10-04 10:17:08', '2026-10-04 10:18:03', '2026-10-04 11:35:23', '2026-10-04 11:34:40', '2026-10-04 11:35:23'),
(3, 'CON-2026-00003', 'dasd', 'asdasdas', 2, 5, 2, 'pending', 'urgent', '2026-10-04 11:01:55', NULL, '2026-10-04 11:01:55', NULL, NULL),
(4, 'CON-2026-00004', 'pipe', 'pipe leak', 3, 2, 3, 'pending', 'high', '2026-10-04 11:51:18', NULL, '2026-10-04 11:51:18', NULL, NULL),
(5, 'CON-2026-00005', 'tiles', 'unmatched on tiles.', 3, 2, 3, 'pending', 'high', '2026-10-04 11:51:41', NULL, '2026-10-04 11:51:41', NULL, NULL),
(6, 'CON-2026-00006', 'tiles', 'tiles has slight crack', 3, 2, 3, 'pending', 'high', '2026-10-04 11:51:59', NULL, '2026-10-04 11:51:59', NULL, NULL),
(7, 'CON-2026-00007', 'tiles', 'tiles has cracked', 3, 2, 3, 'pending', 'high', '2026-10-04 11:52:24', NULL, '2026-10-04 11:52:24', NULL, NULL),
(8, 'CON-2026-00008', 'wall cracked', 'wall has cracked need to fix.', 3, 2, 3, 'pending', 'urgent', '2026-10-04 11:52:56', NULL, '2026-10-04 11:52:56', NULL, NULL),
(9, 'CON-2026-00009', 'Faucet', 'The faucet on CR was broken.', 3, 2, 3, 'pending', 'urgent', '2026-10-04 11:53:34', NULL, '2026-10-04 11:53:34', NULL, NULL),
(10, 'CON-2026-00010', 'dirty floor', 'need to fix the floor because its dirty', 3, 2, 3, 'pending', 'high', '2026-10-04 11:54:04', NULL, '2026-10-04 11:54:04', NULL, NULL),
(11, 'CON-2026-00011', 'No electricity', 'No electricity on our office', 3, 2, 3, 'pending', 'urgent', '2026-10-04 11:54:30', NULL, '2026-10-04 11:54:30', NULL, NULL),
(12, 'CON-2026-00012', 'wire loose', 'need assistance to fix the wire loosen here in our office.', 3, 2, 3, 'pending', 'urgent', '2026-10-04 11:54:55', NULL, '2026-10-04 11:54:55', NULL, NULL),
(13, 'CON-2026-00013', 'ceiling water leaks', 'ceiling water at 3rd lobby', 3, 4, 3, 'closed', 'high', '2026-10-05 07:42:48', '2026-10-05 07:44:54', '2026-10-05 07:57:50', '2026-10-05 07:56:19', '2026-10-05 07:57:50');

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
(3, 1, NULL, 2, 'images.jpg', '/uploads/concerns/concern-1-8386bcdaab4cc2c7eaf8a6870f8b6b06.jpg', 'image/jpeg', 10224, '2026-10-03 21:37:36', NULL, '2026-10-04 00:47:39'),
(6, 1, 4, 2, 'tiles-damage-png.jpg', '/uploads/concerns/comment-4-1791041232928-bdbb57de298188.jpg', 'image/jpeg', 16240, '2026-10-03 23:27:12', NULL, NULL),
(7, 1, 4, 2, 'images.jpg', '/uploads/concerns/comment-4-1791041232929-3302863c9eb4e8.jpg', 'image/jpeg', 10224, '2026-10-03 23:27:12', NULL, NULL),
(8, 1, 5, 2, 'images.jpg', '/uploads/concerns/comment-5-1791041327390-bb46b06bfe4db.jpg', 'image/jpeg', 10224, '2026-10-03 23:28:47', NULL, NULL),
(9, 1, 7, 2, 'tiles-damage-png.jpg', '/uploads/concerns/comment-7-1791041873314-858bce1b9f788.jpg', 'image/jpeg', 16240, '2026-10-03 23:37:53', NULL, NULL),
(10, 1, 8, 2, 'tiles-damage-png.jpg', '/uploads/concerns/comment-8-1791044848201-6a0e6f763de308.jpg', 'image/jpeg', 16240, '2026-10-04 00:27:28', NULL, NULL),
(11, 1, 8, 2, 'tiles3.jpg', '/uploads/concerns/comment-8-1791044848204-a5dd2b4fc1ab9.jpg', 'image/jpeg', 16803, '2026-10-04 00:27:28', NULL, NULL),
(12, 1, 8, 2, 'tiles2.jpg', '/uploads/concerns/comment-8-1791044848205-82d05c9a06fec.jpg', 'image/jpeg', 16958, '2026-10-04 00:27:28', NULL, NULL),
(13, 1, 8, 2, 'tiles1.jpg', '/uploads/concerns/comment-8-1791044848207-fa6c99bac3fb9.jpg', 'image/jpeg', 13907, '2026-10-04 00:27:28', NULL, NULL),
(14, 1, 8, 2, 'images.jpg', '/uploads/concerns/comment-8-1791044848209-125eb8d5c48328.jpg', 'image/jpeg', 10224, '2026-10-04 00:27:28', NULL, NULL),
(15, 1, NULL, 2, 'concern-1-1791047940568-f8n0l8lm.jpg', '/uploads/concerns/concern-1-1791047940568-f8n0l8lm.jpg', 'image/jpeg', 10224, '2026-10-04 01:05:35', '2026-10-04 01:19:00', NULL),
(16, 1, NULL, 2, 'concern-1-1791047135804-ecz7fni7.jpg', '/uploads/concerns/concern-1-1791047135804-ecz7fni7.jpg', 'image/jpeg', 16803, '2026-10-04 01:05:35', NULL, NULL),
(17, 1, NULL, 2, 'concern-1-1791047135805-mfp26wx8.jpg', '/uploads/concerns/concern-1-1791047135805-mfp26wx8.jpg', 'image/jpeg', 16958, '2026-10-04 01:05:35', NULL, NULL),
(18, 1, NULL, 2, 'concern-1-1791047167204-7oiajqvy.jpg', '/uploads/concerns/concern-1-1791047167204-7oiajqvy.jpg', 'image/jpeg', 10224, '2026-10-04 01:05:35', '2026-10-04 01:06:07', NULL),
(19, 2, NULL, 2, 'tiles3.jpg', '/uploads/concerns/concern-2-b8a9319792ff65c6a09541b7db62abb6.jpg', 'image/jpeg', 16803, '2026-10-04 10:17:08', NULL, NULL),
(20, 2, NULL, 2, 'tiles2.jpg', '/uploads/concerns/concern-2-a87dab88da4afb67ea2a40d1285f9008.jpg', 'image/jpeg', 16958, '2026-10-04 10:17:08', NULL, NULL),
(21, 2, NULL, 2, 'tiles1.jpg', '/uploads/concerns/concern-2-5f28f7bbf5cae80718230943fccd3fdd.jpg', 'image/jpeg', 13907, '2026-10-04 10:17:08', NULL, NULL),
(22, 3, NULL, 5, 'tiles1.jpg', '/uploads/concerns/concern-3-5d351a1a2e59af550ff662b56ead594f.jpg', 'image/jpeg', 13907, '2026-10-04 11:01:55', NULL, NULL),
(23, 13, 12, 1, '123.jpg', '/uploads/concerns/comment-12-1791158044734-b7d945002bea2.jpg', 'image/jpeg', 485806, '2026-10-05 07:54:04', NULL, NULL);

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
(2, 1, 2, 'lets see', '2026-10-03 22:11:55', '2026-10-03 22:11:55'),
(3, 1, 5, 'just wait sir', '2026-10-03 22:12:21', '2026-10-03 22:12:21'),
(4, 1, 2, 'Attached Images:', '2026-10-03 23:27:12', '2026-10-03 23:27:12'),
(5, 1, 2, 'image', '2026-10-03 23:28:47', '2026-10-03 23:28:47'),
(6, 1, 2, 'yeah', '2026-10-03 23:37:37', '2026-10-03 23:37:37'),
(7, 1, 2, 'images:', '2026-10-03 23:37:53', '2026-10-03 23:37:53'),
(8, 1, 2, 'test', '2026-10-04 00:27:28', '2026-10-04 00:27:28'),
(9, 1, 5, 'still working', '2026-10-04 01:20:14', '2026-10-04 01:20:14'),
(10, 2, 5, 'working na po', '2026-10-04 10:18:35', '2026-10-04 10:18:35'),
(11, 2, 2, 'ok mam', '2026-10-04 10:19:19', '2026-10-04 10:19:19'),
(12, 13, 1, '', '2026-10-05 07:54:04', '2026-10-05 07:54:04');

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
(1, 2, 1, 5, 'Capture001.png', '/uploads/concerns/status-1-aea2484ca0d650ce65afe6c9261f0de5.png', 'image/png', 1818520, '2026-10-04 08:16:00'),
(2, 5, 2, 5, 'tiles3.jpg', '/uploads/concerns/status-2-e4083bccc2addd2d9178213b6dd2efc7.jpg', 'image/jpeg', 16803, '2026-10-04 11:34:40'),
(3, 8, 13, 5, 'images-removebg-preview.png', '/uploads/concerns/status-13-84164eb47d213d589fbc7d7830e051b8.png', 'image/png', 128296, '2026-10-05 07:56:19');

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
(1, 1, 5, 'pending', 'in_progress', 'ok we start to do it', '2026-10-03 21:49:10'),
(2, 1, 5, 'in_progress', 'resolved', 'yes done.', '2026-10-04 08:16:00'),
(3, 1, 2, 'resolved', 'closed', NULL, '2026-10-04 08:16:47'),
(4, 2, 5, 'pending', 'in_progress', 'acknowledged.', '2026-10-04 10:18:03'),
(5, 2, 5, 'in_progress', 'resolved', 'Done resolve this', '2026-10-04 11:34:40'),
(6, 2, 2, 'resolved', 'closed', NULL, '2026-10-04 11:35:23'),
(7, 13, 5, 'pending', 'in_progress', 'ok we already acknowledge', '2026-10-05 07:44:54'),
(8, 13, 5, 'in_progress', 'resolved', 'already resolved this concern please verify..thank you', '2026-10-05 07:56:19'),
(9, 13, 4, 'resolved', 'closed', NULL, '2026-10-05 07:57:50');

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
(1, 'IT Department', 'Information Technology Department', NULL, NULL, 'UG Alfresco Building A', 'active', '2026-10-01 21:22:29', '2026-10-04 22:36:35', NULL),
(2, 'VXI', 'BPO Company', NULL, NULL, 'Felcris Centrale Building A', 'active', '2026-10-02 11:44:39', '2026-10-02 11:44:39', NULL),
(3, 'Engineering Department', 'Felcris Centrale Engineering Team', NULL, NULL, 'Felcris Centrale UG Parking', 'active', '2026-10-02 14:09:36', '2026-10-04 22:37:00', NULL);

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

INSERT INTO `users` (`id`, `username`, `password_hash`, `first_name`, `middle_name`, `last_name`, `role_id`, `organization_id`, `status`, `last_login_at`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'superadmin', '$2b$12$7Q2BZNGJ8VG8/aX288L7zextU/UWOthz0MWQarPSPUik6UwaYlnXK', 'System', NULL, 'Administrator', 1, NULL, 'active', '2026-10-05 10:01:48', '2026-10-01 21:22:29', '2026-10-05 10:01:48', NULL),
(2, 'anna', '$2b$12$WoKBHfx6YUm5VGwaKVn5V./JI6sx8Iv6czZ/qi8x0ww82a3tfirNy', 'Anna', 'Dela', 'Fuente', 2, 1, 'active', '2026-10-04 22:18:00', '2026-10-02 11:04:52', '2026-10-04 22:18:00', NULL),
(3, 'juan123', '$2b$12$g6jwacvi2I/Mjuxznjqmi.b56UDzfZp3skg6/O6BZtydNNIGeelJq', 'juan', 'dela', 'cruz', 2, 3, 'active', '2026-10-03 23:38:13', '2026-10-03 21:36:12', '2026-10-03 23:38:13', NULL),
(4, 'john', '$2b$12$Sm6WMLnnsr3J.0vG8rWFv.kC71V5KawFXzQ7L11GILFFxDeBuTzNm', 'john', 'doe', 'doe', 2, 2, 'active', '2026-10-05 07:57:20', '2026-10-03 21:46:59', '2026-10-05 07:57:20', NULL),
(5, 'rose', '$2b$12$848WcWXTx.bI9TPSuqDizevBId4ZBemi3u7ASO//MKsAmNyGPolw2', 'rosemarie', NULL, 'dimagiba', 2, 3, 'active', '2026-10-05 07:54:54', '2026-10-03 21:48:33', '2026-10-05 07:54:54', NULL),
(6, 'sample', '$2b$12$p7PWE8B6Awwdjx5zob.sRuv/xW6Yly/ErTIouWyUoZKO/rK131LaC', 'sample', NULL, 'user', 3, 1, 'active', NULL, '2026-10-04 22:13:40', '2026-10-04 22:13:40', NULL);

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
(39, 2, '14bdec5fe98ac0a32a0f9c92068d7e96c938d1fd19e2e4480b2fa68a3e4ce9da', '2026-10-02 22:27:40', '2026-10-02 14:27:40', '2026-10-02 15:05:48'),
(40, 2, 'f9da69c078b5af64dcf3fd5004d4e4d87f5587d4170cac39347f08c9f8961736', '2026-10-04 04:50:14', '2026-10-03 20:50:14', '2026-10-03 21:32:59'),
(41, 1, '4df58c1abd29523edb39feaec8971b1445d88d2ff56c4ea4ff836f19057d9226', '2026-10-04 05:33:04', '2026-10-03 21:33:04', '2026-10-03 21:36:21'),
(42, 3, '57e3c3e891193cf75c42baa205e168a0f7f63ffc9d0ab028b4fac58eae21b6c3', '2026-10-04 05:36:28', '2026-10-03 21:36:28', '2026-10-03 21:36:41'),
(43, 2, '91879ebdf2b26e5c7dd59e06fcfadab58d5a66dfdc5fed2e4a755e1696270e5e', '2026-10-04 05:36:45', '2026-10-03 21:36:45', '2026-10-03 21:37:07'),
(44, 2, 'e4d30fda1e03c06bf1f55588c8815d6ca267b5b25b3a076b0cd3095eb1a2611a', '2026-10-04 05:37:12', '2026-10-03 21:37:12', '2026-10-03 21:37:39'),
(45, 3, 'edf0a05762d510747b74abaaf29c2f9d42d86e12d814704c7322544a3d05c471', '2026-10-04 05:37:45', '2026-10-03 21:37:45', '2026-10-03 21:38:24'),
(46, 2, '7f36cbac7df071e065d222e34ca250043aebb9366c35ecc43f88289de380ee3c', '2026-10-04 05:38:27', '2026-10-03 21:38:27', '2026-10-03 21:46:23'),
(47, 3, '01f2ea4a209accb15b2f388159d5b998dff2c14ae2a86faa643b1a241f33e406', '2026-10-04 05:46:28', '2026-10-03 21:46:28', '2026-10-03 21:46:37'),
(48, 1, 'c56ea55ad12cfe3663e6796d0692c81cc9e2e792e120943a2b3d20f0dccbe7c0', '2026-10-04 05:46:40', '2026-10-03 21:46:40', '2026-10-03 21:47:07'),
(49, 4, '5356d52121147f0741d5d9be0a9b88a8e40b0d13011ee10fd53aede6f7f989f7', '2026-10-04 05:47:14', '2026-10-03 21:47:14', '2026-10-03 21:47:33'),
(50, 2, '0a7b05a19e94d758e20e3a45d991b569eedc3d0a811682d1ae61bd46d69288c6', '2026-10-04 05:47:45', '2026-10-03 21:47:45', '2026-10-03 21:47:51'),
(51, 1, '117c1dc3af3b625b35269e91a5d4da51ffa477aeb681f66ff79cc65f3d8b262c', '2026-10-04 05:47:57', '2026-10-03 21:47:57', '2026-10-03 21:48:36'),
(52, 5, '0c0d19858334dedd5bbc75bcc2ca1d88c8174f5cb85b5b7430d9d12783a6b5e6', '2026-10-04 05:48:40', '2026-10-03 21:48:40', '2026-10-03 21:49:30'),
(53, 2, '96924ed251b35f1f43fcd5156988beb6f2cc8703416c58d16127f00991032d51', '2026-10-04 05:49:40', '2026-10-03 21:49:40', '2026-10-03 21:52:42'),
(54, 5, '6dde085801ad460adefc8b0009911b06e9fd208cd35dbdba91f14cdf9c43b895', '2026-10-04 05:52:50', '2026-10-03 21:52:50', '2026-10-03 21:53:22'),
(55, 2, '2c4611c4e3a11af42bc905bd124427574e343ad21806dc7bee6f3d06075f33c4', '2026-10-04 06:11:21', '2026-10-03 22:11:21', '2026-10-03 22:11:29'),
(56, 5, '96fc0ce8203adf3774d5eba86cd9635ab0bfbf2ab61ea0656707a1fa576ac65c', '2026-10-04 06:11:33', '2026-10-03 22:11:33', '2026-10-03 22:11:41'),
(57, 2, '8c40203e8898b1193f2b7e46fd5a436c31c049539a72975e0261b55410aed10b', '2026-10-04 06:11:46', '2026-10-03 22:11:46', '2026-10-03 22:12:00'),
(58, 5, 'aede31c0ce79a0f565ebff6b1ea22a932be2af81861fb3756972880f9063ae4a', '2026-10-04 06:12:03', '2026-10-03 22:12:03', '2026-10-03 22:27:06'),
(59, 2, '80b1ab4381ab228f33b148ca99eab162989ce1209a3100b76e767085fc88ce41', '2026-10-04 06:27:10', '2026-10-03 22:27:10', '2026-10-03 22:28:19'),
(60, 4, 'f54253bf807bcf49a4cdccf3e326dc8c8f4cf178e19127f53eadc33ba1760577', '2026-10-04 06:28:29', '2026-10-03 22:28:29', '2026-10-03 22:31:40'),
(61, 2, 'c0942275a161ee4765367ea3532b13df195f065bffc24246cdc50af8da975d3c', '2026-10-04 06:31:43', '2026-10-03 22:31:43', '2026-10-03 23:38:08'),
(62, 3, '162a66bd9991e644a5da5cd530670c3794fc16429eb617de5acf5c0d9146bdfe', '2026-10-04 07:38:13', '2026-10-03 23:38:13', '2026-10-03 23:38:35'),
(63, 2, 'a275de8c65c3eeb0175ceb5b174045fa9befd4dd82bca90ee54f71e181aa076f', '2026-10-04 07:39:39', '2026-10-03 23:39:39', '2026-10-04 00:46:04'),
(64, 5, '7a7bd696caddc2c412991ec590a37ecbd2aa32b91572454bc6ca28f4916ddbee', '2026-10-04 08:46:09', '2026-10-04 00:46:09', '2026-10-04 00:46:16'),
(65, 4, '68b60ddfb496ffdfb0414b0e18bc3e0ab765f87ec6bc585a49f63a369fb50d64', '2026-10-04 08:46:23', '2026-10-04 00:46:23', '2026-10-04 00:46:26'),
(66, 2, '771750fbb6a5e0b8fee67fa99c7d5b2f450f1d60754cf0a3dd34bcce81f1b581', '2026-10-04 08:46:32', '2026-10-04 00:46:32', '2026-10-04 01:04:32'),
(67, 1, 'ec66fc16178929a5fe0f414260e2a986065f43ff5c9ce18632a6a9299c2a0492', '2026-10-04 09:05:10', '2026-10-04 01:05:10', '2026-10-04 01:05:18'),
(68, 2, '388c29da6446fce308f3d0a0e2cd0d2dff0fd681aea01739169d9e042d5d5368', '2026-10-04 09:05:24', '2026-10-04 01:05:24', '2026-10-04 01:19:33'),
(69, 5, '1435e4b5713857625a1d62ebfa414f2641721c63c7d70e45529ef4d0ccf8fd37', '2026-10-04 09:19:37', '2026-10-04 01:19:37', '2026-10-04 01:20:18'),
(70, 2, '0616f21f17b7687cfa1911cea1a1bf1faaefe49016a5335c76abec59a2d75f6c', '2026-10-04 09:20:22', '2026-10-04 01:20:22', '2026-10-04 01:20:49'),
(71, 1, '21ac323dde2ac542d34202d4811127e1758d65413ec2ed8a2bb73f7baced9032', '2026-10-04 15:06:20', '2026-10-04 07:06:20', '2026-10-04 07:06:22'),
(72, 2, '4cc29d57f08a3281926432b4f74ddd470a970fe36417c0a80bb914e70f01d176', '2026-10-04 15:06:27', '2026-10-04 07:06:27', '2026-10-04 07:07:33'),
(73, 5, '498a8ead292ca4f4e9b554047069fb4c53801a8d5c21dea145ad89c36617155c', '2026-10-04 15:07:37', '2026-10-04 07:07:37', '2026-10-04 07:08:15'),
(74, 2, '9c58f72bd21d4000d13f0891eb9de854c9ca900309fd95ac2400326cd29f1f23', '2026-10-04 15:08:18', '2026-10-04 07:08:18', '2026-10-04 07:43:17'),
(75, 5, '6f38022953f8efb0a834afde08e8363920e1af8794823f9e5e7c00c430e3b203', '2026-10-04 15:43:25', '2026-10-04 07:43:25', '2026-10-04 08:16:28'),
(76, 2, '3b9f95fd1d0efe1ef3d078a90be8581e07ae9338175c224a539981a5b5e4377a', '2026-10-04 16:16:33', '2026-10-04 08:16:33', '2026-10-04 09:22:29'),
(77, 5, '45a75500ae6fae5f938be9983c11fec9ee7011c0fbe2c283aff65e3ebf0e99a2', '2026-10-04 17:22:33', '2026-10-04 09:22:33', '2026-10-04 09:22:41'),
(78, 2, '37aef15b2a4117812778040ab979a7949876e8dd5374ffef25472e526014af5e', '2026-10-04 17:32:34', '2026-10-04 09:32:34', '2026-10-04 10:17:29'),
(79, 5, 'abccf1f0b434f59c343fc0a209037df7c8f5c0919abf06dbca65c7c68e923a50', '2026-10-04 18:17:33', '2026-10-04 10:17:33', '2026-10-04 10:19:06'),
(80, 2, '1762aa93b0a6a6c1fcfbba1afb8fc0ab8abe3a0ac6fbfc7100fa5efb8297af10', '2026-10-04 18:19:09', '2026-10-04 10:19:09', '2026-10-04 10:19:33'),
(81, 5, 'b60731485c9fb975e5440ea9710de8d9c223bf4ac845ed62b46bff3169420f29', '2026-10-04 18:19:39', '2026-10-04 10:19:39', '2026-10-04 11:33:49'),
(82, 5, '19f1e22d13b6c83a5f8675658d7bfcd3b8d9a63abbf5c5f1312c579aaef2738d', '2026-10-04 19:33:54', '2026-10-04 11:33:54', '2026-10-04 11:34:49'),
(83, 2, '8245889c9b2582f6d47263b175fa595389310225e695c72e79c8be7140a00078', '2026-10-04 19:34:53', '2026-10-04 11:34:53', '2026-10-04 14:59:41'),
(84, 2, 'c10f09214332ca5107ff8e8ac047f832a33e2c212fb2a9b793fcf1478e717835', '2026-10-04 19:58:30', '2026-10-04 11:58:30', '2026-10-04 11:58:57'),
(85, 1, '96c4b4d8322ce5452af3e2baa2095a15a32b44e5f9a1982aa2515ae07bb5987b', '2026-10-04 22:59:46', '2026-10-04 14:59:46', NULL),
(86, 1, '596e8e6012c273af7e212e0fefacd3623547755e72f420ffa9bdcaf06f88f142', '2026-10-04 23:46:31', '2026-10-04 15:46:31', '2026-10-04 16:21:24'),
(87, 1, '61b5426d9306b00086acbeba5e1befa8fdfb64e782918d12fbaa9c47420f24ce', '2026-10-05 00:21:36', '2026-10-04 16:21:36', '2026-10-04 16:34:04'),
(88, 1, 'b9bf98486e282fa347032feea125acde1c5a5ba7ee149cc1d48681a539226e03', '2026-10-05 00:34:19', '2026-10-04 16:34:19', '2026-10-04 16:34:25'),
(89, 4, '7963dd1a77eafa84ef6fd46bbf1004531c9a8d7be3583f6b0f9a8a439fca89c1', '2026-10-05 00:34:28', '2026-10-04 16:34:28', '2026-10-04 16:34:30'),
(90, 1, 'a4d932fec0608e6d4ea0847597b74c57aa099eede090ce9054adfee94fd23c94', '2026-10-05 00:34:34', '2026-10-04 16:34:34', '2026-10-04 16:46:03'),
(91, 1, '57a79ef4f7f842ca40cf0375fbfe77da4a874be30059ef9db6dbad778218f727', '2026-10-05 05:25:19', '2026-10-04 21:25:19', NULL),
(92, 1, '8dc1b887e1998a6c369819780a820f36e1058cd5ca8348c1a35a51b161960791', '2026-10-05 05:27:33', '2026-10-04 21:27:33', '2026-10-04 22:17:47'),
(93, 2, '23865d0d129dcabdd7d21eaeec3d5bc538433021465ca2b216b291d9dfac7e24', '2026-10-05 06:18:00', '2026-10-04 22:18:00', '2026-10-04 22:26:35'),
(94, 1, '96d1fd7e270eecea8e8d4f10e418ded1c3cbd5ce13580c11b59ee0e0a63a31d2', '2026-10-05 06:26:39', '2026-10-04 22:26:39', '2026-10-04 23:49:42'),
(95, 1, 'acd5a71865b0c7687e2140afc209c3a3c96ce03954f707ea869c1f32c859532e', '2026-10-05 15:37:55', '2026-10-05 07:37:55', NULL),
(96, 4, '7b78b79ae2a4381111ba5c02b0ea0dbcc89628a81b4427ccbeafee7dfb22b776', '2026-10-05 15:40:12', '2026-10-05 07:40:12', NULL),
(97, 5, 'b138910ca4d474dfab9c95edb5bdf48d09cc3c48e54ba5c4fce33d2bb8cf7db8', '2026-10-05 15:43:45', '2026-10-05 07:43:45', NULL),
(98, 5, '5aae9692dcef2e77d72d9500fc0ee97c40558205f4474de3f7d2b9bc148d36c2', '2026-10-05 15:54:54', '2026-10-05 07:54:54', '2026-10-05 08:19:27'),
(99, 4, 'dd9a33b759336b355c72e4986a708e7587a6c601026063404322c3980b4bf524', '2026-10-05 15:57:20', '2026-10-05 07:57:20', NULL),
(100, 1, '4f948468b7d73fc623cfc0f1f8ce66807dd454e90da63408db986d1048d204a2', '2026-10-05 16:09:17', '2026-10-05 08:09:17', '2026-10-05 09:13:43'),
(101, 1, 'eac1147ef0b1fc8e9af18411f56ce102d223211b419179666559dac53ca34456', '2026-10-05 16:15:19', '2026-10-05 08:15:19', '2026-10-05 09:14:19'),
(102, 1, '65178ea53e51c42155af32b95804de2bf8ecc90f41785b0f140d36f955c4ec4b', '2026-10-05 16:17:55', '2026-10-05 08:17:55', '2026-10-05 09:16:27'),
(103, 1, 'b5e53e477712dedbabf450511e29bebec77575c42d3dcc4f23b56fe98e70f579', '2026-10-05 17:15:42', '2026-10-05 09:15:42', '2026-10-05 09:15:43'),
(104, 1, 'ec8b4fe8f5bd92130f1c18128a2c2281e5a77687857e776c0902303d99a35072', '2026-10-05 17:16:09', '2026-10-05 09:16:09', '2026-10-05 09:26:01'),
(105, 1, '71df46b3e4479c2673c4884695e2f037b03e095a9eb571e764860e4f72f5e462', '2026-10-05 17:16:39', '2026-10-05 09:16:39', '2026-10-05 09:17:32'),
(106, 1, '71b74d8410303c5941069adb09b289d38a683066ed37f0d1eacf9091f4c049b8', '2026-10-05 17:17:46', '2026-10-05 09:17:46', '2026-10-05 09:18:03'),
(107, 1, '29d67185ae5baceb5580eecd5ed7af4308b36f6c281f0ac18b0ebebf9bfc4bb6', '2026-10-05 17:27:30', '2026-10-05 09:27:30', '2026-10-05 09:28:03'),
(108, 1, 'ffe052222e27ddddacb2b830fac3edcfabdee884c83a1bfbbdf8e720eea39e8e', '2026-10-05 17:31:37', '2026-10-05 09:31:37', '2026-10-05 09:32:03'),
(109, 1, '725747d4c51c6e823de169bde8cdf7eee62f38a9f335210be051a40785db61e4', '2026-10-05 17:34:23', '2026-10-05 09:34:23', '2026-10-05 09:34:37'),
(110, 1, '277853424600b14bcf09a7f9aab2ca9300fb2ceb073969afb03c9c429cd6ed2a', '2026-10-05 17:34:42', '2026-10-05 09:34:42', '2026-10-05 09:37:27'),
(111, 1, '652fd9a37710a174a05f1436cd278ee0a924c8964880241ad20d490d7f81e9ce', '2026-10-05 17:36:32', '2026-10-05 09:36:32', '2026-10-05 09:37:20'),
(112, 1, 'fae630ea8e65ba962102f8141fbc5bded77a52d89a60e60c1b11582849fd0a6c', '2026-10-05 17:44:12', '2026-10-05 09:44:12', '2026-10-05 09:47:23'),
(113, 1, 'cc6422b83ce02561bad473a1ef428dc806e7383216593a6cb2129fd118ec7841', '2026-10-05 17:56:36', '2026-10-05 09:56:36', NULL),
(114, 1, 'c1f9fb77ef96e2ffae868456f3cb051dac94bba4fae18218abfb64254d163f40', '2026-10-05 17:59:04', '2026-10-05 09:59:04', NULL),
(115, 1, '217daeb29b8d3e9eab1374e6c26e1b8aa4fb8faca15ff3867122b786c43ec99c', '2026-10-05 18:01:48', '2026-10-05 10:01:48', NULL);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `concern_comments`
--
ALTER TABLE `concern_comments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `concern_status_attachments`
--
ALTER TABLE `concern_status_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `concern_status_history`
--
ALTER TABLE `concern_status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=116;

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
