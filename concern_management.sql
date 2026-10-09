-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 09, 2026 at 07:11 AM
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
  `closed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `concerns`
--

INSERT INTO `concerns` (`id`, `concern_number`, `title`, `description`, `concern_type_id`, `created_by`, `assigned_organization_id`, `status`, `priority`, `created_at`, `target_commitment_at`, `updated_at`, `resolved_at`, `closed_at`) VALUES
(1, 'CON-2026-00001', 'waterleaks', 'waterleaks at UG alfresco', 3, 4, 3, 'in_progress', 'high', '2026-10-07 08:21:51', '2026-10-07 09:01:00', '2026-10-07 08:59:49', NULL, NULL),
(2, 'CON-2026-00002', 'leaks', 'water leaks at cr male 3rd floor', 2, 4, 3, 'in_progress', 'high', '2026-10-07 09:33:02', '2026-10-07 09:36:00', '2026-10-07 09:35:14', NULL, NULL),
(3, 'CON-2026-00003', 'wall cracks', 'wall cracks at our hallway', 3, 4, 3, 'resolved', 'high', '2026-10-07 09:53:14', '2026-10-09 17:43:00', '2026-10-09 12:44:59', '2026-10-09 12:44:59', NULL),
(4, 'CON-2026-00004', 'test', 'testing', 3, 6, 2, 'resolved', 'urgent', '2026-10-07 14:13:27', '2026-10-07 14:50:00', '2026-10-07 14:30:11', '2026-10-07 14:30:11', NULL),
(5, 'CON-2026-00005', 'test', 'test1', 3, 6, 2, 'closed', 'urgent', '2026-10-08 10:24:59', '2026-10-08 00:00:00', '2026-10-08 10:29:20', '2026-10-08 10:28:09', '2026-10-08 10:29:20'),
(6, 'CON-2026-00006', 'test2', 'test2', 3, 5, 2, 'closed', 'high', '2026-10-08 16:46:34', '2026-10-08 00:00:00', '2026-10-08 16:51:55', '2026-10-08 16:49:12', '2026-10-08 16:51:55'),
(7, 'CON-2026-00007', 'test3', 'test3', 3, 5, 1, 'pending', 'urgent', '2026-10-08 16:52:08', NULL, '2026-10-08 16:52:08', NULL, NULL),
(8, 'CON-2026-00008', 'test4', 'test4', 3, 4, 3, 'in_progress', 'high', '2026-10-08 16:52:50', '2026-10-09 12:46:00', '2026-10-09 11:46:16', NULL, NULL),
(9, 'CON-2026-00009', 'test5', 'test5', 3, 6, 2, 'closed', 'urgent', '2026-10-08 16:53:13', '2026-10-09 00:00:00', '2026-10-09 09:25:56', '2026-10-09 09:24:10', '2026-10-09 09:25:56'),
(10, 'CON-2026-00010', 'test6', 'test6', 3, 5, 2, 'closed', 'urgent', '2026-10-09 09:27:54', '2026-10-09 12:00:00', '2026-10-09 13:05:09', '2026-10-09 11:42:53', '2026-10-09 13:05:09'),
(11, 'CON-2026-00011', 'test7', 'test7', 3, 6, 2, 'in_progress', 'urgent', '2026-10-09 13:05:49', '2026-10-11 08:00:00', '2026-10-09 13:08:03', NULL, NULL);

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
(1, 3, NULL, 4, 'concern-3-1791338041884-nrkg6rxe.jpeg', '/uploads/concerns/concern-3-1791338041884-nrkg6rxe.jpeg', 'image/jpeg', 39574, '2026-10-07 09:54:01', NULL, NULL),
(2, 3, NULL, 4, 'concern-3-1791340139997-483msyq5.jpg', '/uploads/concerns/concern-3-1791340139997-483msyq5.jpg', 'image/jpeg', 22673, '2026-10-07 10:22:25', '2026-10-07 10:29:00', NULL),
(3, 2, 2, 6, 'wall-crack.jpeg', '/uploads/concerns/comment-2-1791353293707-bb8e85abe13c9.jpeg', 'image/jpeg', 39574, '2026-10-07 14:08:13', NULL, NULL),
(4, 4, NULL, 6, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/concern-4-134a7b8f659c30dfa8fe1917f555488a.jpg', 'image/jpeg', 29037, '2026-10-07 14:13:27', NULL, NULL),
(5, 5, 5, 6, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/comment-5-1791426326967-296d0da7785938.jpg', 'image/jpeg', 29037, '2026-10-08 10:25:26', NULL, NULL),
(6, 5, 7, 4, 'wall-crack-2.jpeg', '/uploads/concerns/comment-7-1791426413096-6b17b68f91981.jpeg', 'image/jpeg', 22673, '2026-10-08 10:26:53', NULL, NULL),
(7, 9, 13, 4, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/comment-13-1791509066585-fadc59b263dcc.jpg', 'image/jpeg', 29037, '2026-10-09 09:24:26', NULL, NULL),
(8, 9, 15, 6, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/comment-15-1791509098105-0c48db9fbd9288.jpg', 'image/jpeg', 29037, '2026-10-09 09:24:58', NULL, NULL),
(9, 9, 17, 5, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/comment-17-1791509140381-f99edc1e144af.jpg', 'image/jpeg', 29037, '2026-10-09 09:25:40', NULL, NULL),
(10, 10, 19, 5, 'wall-crack-2.jpeg', '/uploads/concerns/comment-19-1791509285581-1e0d5fd7b645.jpeg', 'image/jpeg', 22673, '2026-10-09 09:28:05', NULL, NULL),
(11, 10, 22, 4, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/comment-22-1791509374786-1ede5df29b5be8.jpg', 'image/jpeg', 29037, '2026-10-09 09:29:34', NULL, NULL),
(12, 11, NULL, 6, 'IMG_20260510_130017.jpg', '/uploads/concerns/concern-11-b7876d0f18e0286573c5f0210806100a.jpg', 'image/jpeg', 2728270, '2026-10-09 13:05:49', NULL, NULL),
(13, 11, 27, 6, '123.png', '/uploads/concerns/comment-27-1791522362782-6c576443f88c1.png', 'image/png', 252978, '2026-10-09 13:06:02', NULL, NULL);

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
(1, 2, 5, 'ok', '2026-10-07 09:37:39', '2026-10-07 09:37:39'),
(2, 2, 6, 'try', '2026-10-07 14:08:13', '2026-10-07 14:08:13'),
(4, 5, 6, 'i want a perfect work ok.', '2026-10-08 10:25:18', '2026-10-08 10:25:18'),
(5, 5, 6, '', '2026-10-08 10:25:26', '2026-10-08 10:25:26'),
(6, 5, 4, 'test', '2026-10-08 10:26:46', '2026-10-08 10:26:46'),
(7, 5, 4, 'test1', '2026-10-08 10:26:53', '2026-10-08 10:26:53'),
(8, 6, 4, 'yeah', '2026-10-08 16:46:47', '2026-10-08 16:46:47'),
(9, 9, 6, 'try', '2026-10-08 16:53:18', '2026-10-08 16:53:18'),
(10, 9, 4, 'try2', '2026-10-08 16:53:36', '2026-10-08 16:53:36'),
(11, 9, 6, 'try3', '2026-10-09 09:09:18', '2026-10-09 09:09:18'),
(12, 9, 4, 'try4', '2026-10-09 09:24:18', '2026-10-09 09:24:18'),
(13, 9, 4, 'try5', '2026-10-09 09:24:26', '2026-10-09 09:24:26'),
(14, 9, 6, 'try6', '2026-10-09 09:24:50', '2026-10-09 09:24:50'),
(15, 9, 6, 'try7', '2026-10-09 09:24:58', '2026-10-09 09:24:58'),
(16, 9, 5, 'try8', '2026-10-09 09:25:15', '2026-10-09 09:25:15'),
(17, 9, 5, 'try91234', '2026-10-09 09:25:40', '2026-10-09 09:25:40'),
(18, 10, 5, 'test', '2026-10-09 09:27:59', '2026-10-09 09:27:59'),
(19, 10, 5, 'test1', '2026-10-09 09:28:05', '2026-10-09 09:28:05'),
(20, 10, 6, 'test', '2026-10-09 09:29:05', '2026-10-09 09:29:05'),
(21, 10, 6, 'test3', '2026-10-09 09:29:08', '2026-10-09 09:29:08'),
(22, 10, 4, 'test4', '2026-10-09 09:29:34', '2026-10-09 09:29:34'),
(23, 10, 4, 'test', '2026-10-09 11:43:00', '2026-10-09 11:43:00'),
(24, 3, 5, 'test', '2026-10-09 12:44:47', '2026-10-09 12:44:47'),
(25, 10, 5, 'test', '2026-10-09 13:03:08', '2026-10-09 13:03:08'),
(26, 11, 6, 'test123', '2026-10-09 13:05:55', '2026-10-09 13:05:55'),
(27, 11, 6, 'test1234', '2026-10-09 13:06:02', '2026-10-09 13:06:02');

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
(1, 5, 4, 4, '442a3666-40d7-4e25-af8e-cc861764989f.jpeg', '/uploads/concerns/status-4-630a798367458e048e45a5d03c097a76.jpeg', 'image/jpeg', 260777, '2026-10-07 14:30:11'),
(2, 9, 5, 4, 'thread-connection-pipe-valve-with-seal-tape-for-protection-of-leak-photo.jpg', '/uploads/concerns/status-5-5194266506052c9f5fd0513becc20bcc.jpg', 'image/jpeg', 29037, '2026-10-08 10:28:09'),
(3, 13, 6, 4, 'wall-crack.jpeg', '/uploads/concerns/status-6-92109fb133e50cd4b52f70ddbc2041f8.jpeg', 'image/jpeg', 39574, '2026-10-08 16:49:12'),
(4, 17, 9, 4, 'wall-crack.jpeg', '/uploads/concerns/status-9-d22b9ff71bb581df6c7cc30bfea8195a.jpeg', 'image/jpeg', 39574, '2026-10-09 09:24:10'),
(5, 21, 10, 4, 'update-before.png', '/uploads/concerns/status-10-59c278a11be1573371bb02b9a30702b3.png', 'image/png', 51841, '2026-10-09 11:42:53'),
(6, 24, 3, 5, 'update-before.png', '/uploads/concerns/status-3-6f91b05497e43b5d3a5e2c8732494f69.png', 'image/png', 51841, '2026-10-09 12:44:59');

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
(1, 1, 5, 'pending', 'in_progress', 'We\'re working on it.', '2026-10-07 08:59:49'),
(2, 2, 5, 'pending', 'in_progress', 'waiting for materials', '2026-10-07 09:35:14'),
(3, 3, 5, 'pending', 'on_hold', 'We work it later', '2026-10-07 09:55:15'),
(4, 4, 4, 'pending', 'in_progress', 'in progress', '2026-10-07 14:28:47'),
(5, 4, 4, 'in_progress', 'resolved', 'done', '2026-10-07 14:30:11'),
(7, 5, 4, 'pending', 'on_hold', 'dasdasdasd', '2026-10-08 10:26:30'),
(8, 5, 4, 'on_hold', 'in_progress', 'test123', '2026-10-08 10:27:32'),
(9, 5, 4, 'in_progress', 'resolved', 'done', '2026-10-08 10:28:09'),
(10, 5, 5, 'resolved', 'closed', NULL, '2026-10-08 10:29:20'),
(11, 6, 4, 'pending', 'on_hold', 'test', '2026-10-08 16:46:56'),
(12, 6, 4, 'on_hold', 'in_progress', 'test', '2026-10-08 16:47:11'),
(13, 6, 4, 'in_progress', 'resolved', 'test1', '2026-10-08 16:49:12'),
(14, 6, 5, 'resolved', 'closed', NULL, '2026-10-08 16:51:55'),
(15, 9, 4, 'pending', 'on_hold', 'test1', '2026-10-09 09:23:40'),
(16, 9, 4, 'on_hold', 'in_progress', 'test3', '2026-10-09 09:23:57'),
(17, 9, 4, 'in_progress', 'resolved', 'test4', '2026-10-09 09:24:10'),
(18, 9, 5, 'resolved', 'closed', NULL, '2026-10-09 09:25:56'),
(19, 10, 4, 'pending', 'on_hold', 'test', '2026-10-09 09:30:02'),
(20, 10, 4, 'on_hold', 'in_progress', 'test123', '2026-10-09 11:42:09'),
(21, 10, 4, 'in_progress', 'resolved', 'test', '2026-10-09 11:42:53'),
(22, 8, 5, 'pending', 'in_progress', 'test123', '2026-10-09 11:46:16'),
(23, 3, 5, 'on_hold', 'in_progress', 'test', '2026-10-09 12:43:21'),
(24, 3, 5, 'in_progress', 'resolved', 'test', '2026-10-09 12:44:59'),
(25, 10, 5, 'resolved', 'closed', 'test123', '2026-10-09 13:05:10'),
(26, 11, 4, 'pending', 'in_progress', 'test123\nTarget resolution date: 2026-10-11 08:00:00', '2026-10-09 13:08:03');

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

INSERT INTO `users` (`id`, `username`, `password_hash`, `first_name`, `middle_name`, `last_name`, `role_id`, `organization_id`, `profile_photo`, `status`, `last_login_at`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'superadmin', '$2b$12$7Q2BZNGJ8VG8/aX288L7zextU/UWOthz0MWQarPSPUik6UwaYlnXK', 'System', NULL, 'Administrator', 1, NULL, '/uploads/users/0f5206e8-6c0d-46cc-9b3f-a59d4ee8e31c.png', 'active', '2026-10-09 13:08:18', '2026-10-01 21:22:29', '2026-10-09 13:08:18', NULL),
(2, 'anna', '$2b$12$WoKBHfx6YUm5VGwaKVn5V./JI6sx8Iv6czZ/qi8x0ww82a3tfirNy', 'Anna', 'Dela', 'Fuente', 2, 1, NULL, 'active', '2026-10-04 22:18:00', '2026-10-02 11:04:52', '2026-10-04 22:18:00', NULL),
(3, 'juan123', '$2b$12$g6jwacvi2I/Mjuxznjqmi.b56UDzfZp3skg6/O6BZtydNNIGeelJq', 'juan', 'dela', 'cruz', 2, 3, NULL, 'active', '2026-10-05 16:18:53', '2026-10-03 21:36:12', '2026-10-05 16:18:53', NULL),
(4, 'john', '$2b$12$Sm6WMLnnsr3J.0vG8rWFv.kC71V5KawFXzQ7L11GILFFxDeBuTzNm', 'john', 'doe', 'doe', 2, 2, NULL, 'active', '2026-10-09 13:06:36', '2026-10-03 21:46:59', '2026-10-09 13:06:36', NULL),
(5, 'rose', '$2b$12$848WcWXTx.bI9TPSuqDizevBId4ZBemi3u7ASO//MKsAmNyGPolw2', 'rosemarie', NULL, 'dimagiba', 2, 3, NULL, 'active', '2026-10-09 13:09:08', '2026-10-03 21:48:33', '2026-10-09 13:09:08', NULL),
(6, 'sample', '$2b$12$p7PWE8B6Awwdjx5zob.sRuv/xW6Yly/ErTIouWyUoZKO/rK131LaC', 'sample', NULL, 'user', 3, 3, NULL, 'active', '2026-10-09 13:05:28', '2026-10-04 22:13:40', '2026-10-09 13:05:28', NULL);

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
(115, 1, '217daeb29b8d3e9eab1374e6c26e1b8aa4fb8faca15ff3867122b786c43ec99c', '2026-10-05 18:01:48', '2026-10-05 10:01:48', NULL),
(116, 1, '202f336105d837bb0855883d4b1484235656ef4d0dee0b2e0791f487d972fc32', '2026-10-05 20:45:17', '2026-10-05 12:45:17', '2026-10-05 12:46:23'),
(117, 5, '8bd827a1102433c87aa17cb9cc18c00de4baee01b84772da8235f523007d3ea3', '2026-10-05 20:46:27', '2026-10-05 12:46:27', '2026-10-05 13:22:10'),
(118, 1, '85285cb49e97c7086f7bc4e2d1ab594dc7e342235d48119c17f03ddb335ac5e7', '2026-10-05 20:47:10', '2026-10-05 12:47:10', '2026-10-05 12:48:03'),
(119, 1, '39177a603e7c05eab6bf98f0210399d12a400856fb0d1dd0518ce22a3b9f03f8', '2026-10-05 20:48:13', '2026-10-05 12:48:13', '2026-10-05 12:49:34'),
(120, 1, '587f670419df4195244d33c97a85a27afd98bf4a0153e4a92e0e41e01640d868', '2026-10-05 21:05:45', '2026-10-05 13:05:45', NULL),
(121, 1, '7674df113e1334dd5049afa52ca8d0bfad2e84e9edd763315c1fb9ed1dd7f66d', '2026-10-05 21:21:55', '2026-10-05 13:21:55', '2026-10-05 13:22:43'),
(122, 1, 'c991f2e9a7cfe6259b81090d27ee5a9aee491a371f6482f2ca752b88aae45127', '2026-10-05 21:22:18', '2026-10-05 13:22:18', '2026-10-05 13:25:05'),
(123, 1, '648dfc5e411d4fa16e5ca3ce13cd397f0a598941d46f411e3920d724bf8699b8', '2026-10-05 21:25:29', '2026-10-05 13:25:29', '2026-10-05 13:25:57'),
(124, 1, 'd71557582495ae8fae60d1442724ffbf5c2b8408ecb129d9270149e22bee59ad', '2026-10-05 21:28:14', '2026-10-05 13:28:14', NULL),
(125, 1, '608bd7c79d9abd0cc276e0ba54f639c58b802edcddd2d48d59874f3fcbbe8078', '2026-10-05 21:28:43', '2026-10-05 13:28:43', '2026-10-05 13:33:38'),
(126, 1, '64bd606cd1d9331f33acb5ce0f6367ab5de00f9903c8c21bb0e98c5c3efabea9', '2026-10-05 21:37:21', '2026-10-05 13:37:21', '2026-10-05 13:38:23'),
(127, 1, '1f6f85267ae5538dd36aea178e87c8d2678d8d18105e9c3f3793ce76ffaf74f3', '2026-10-05 21:43:36', '2026-10-05 13:43:36', '2026-10-05 13:45:20'),
(128, 1, '58c3f8dec58473ace8d783d960e8dc5f7acd29a1a9589f513f4e2332e4edf9d0', '2026-10-05 21:46:50', '2026-10-05 13:46:50', '2026-10-05 13:58:49'),
(129, 1, 'e61c561f26f9c3dd980af137ca4bce6cf93ed107fb28fb8e3ca63117eec29d94', '2026-10-05 22:09:01', '2026-10-05 14:09:01', '2026-10-05 14:09:20'),
(130, 1, '6d0b7072778c5d13f11f3542d9bdb02f8e085da7516ddab95675ada06eadcb5b', '2026-10-05 22:23:40', '2026-10-05 14:23:40', '2026-10-05 14:31:26'),
(131, 1, '0d87ae3f1adf58475ceadbef1138578e7b0a7b62a6a10440e5c5397e960f1b5f', '2026-10-05 22:31:52', '2026-10-05 14:31:52', '2026-10-05 15:12:44'),
(132, 1, '7f3ff634268aa49e2265fa4749947cb3080d6df34f856a3612af0c2f35040cd1', '2026-10-05 23:09:26', '2026-10-05 15:09:26', '2026-10-05 16:17:59'),
(133, 1, '48952e962e6ad0393a47799b04624f24444ff8b51251a21df01af7002ab88967', '2026-10-05 23:13:09', '2026-10-05 15:13:09', '2026-10-05 16:01:10'),
(134, 1, '935d0d5455c078474b51c193167e57414c762b80db2637cf1d0cc0aedc60e0de', '2026-10-05 23:40:11', '2026-10-05 15:40:11', '2026-10-05 15:41:14'),
(135, 5, 'aef8f43f2620d29214f4639739e4eb32f83025e7381dad7d9c952fb308ff83ea', '2026-10-05 23:41:31', '2026-10-05 15:41:31', NULL),
(136, 1, 'eed221538680a25dfa68c9d7860fef363eb700d6f120f592f2fb80150fd7319f', '2026-10-05 23:46:26', '2026-10-05 15:46:26', '2026-10-05 15:47:01'),
(137, 4, '5f4a648de7496aa317d11d47fad9e36ac027904f93417f35f2529da939de006e', '2026-10-05 23:47:12', '2026-10-05 15:47:12', '2026-10-05 15:55:50'),
(138, 1, 'b391de8a534da46287663a82299b0dc3af8d7b53280fe4f9396572a4f0dff70a', '2026-10-05 23:56:04', '2026-10-05 15:56:04', NULL),
(139, 1, '8b96da5c43660d1250677728eb703c8d2901cd5a8b2351359fa04832a58eb73c', '2026-10-06 00:01:02', '2026-10-05 16:01:02', '2026-10-05 16:03:42'),
(140, 1, '02c9ee8f73b808dc9bd3e6d8990284902d9f14170467e31b9580384ee97a4b10', '2026-10-06 00:18:07', '2026-10-05 16:18:07', '2026-10-05 16:18:38'),
(141, 3, 'af3e41c6204308550b4ca246794983ea9b5c95a0ecb7de6eea07dc6f8a434cbd', '2026-10-06 00:18:53', '2026-10-05 16:18:53', '2026-10-05 16:22:47'),
(142, 1, '3b81e41fa551ef4894a98b114db45b6db95559ba441ed626c48a59c65f041cb8', '2026-10-06 00:24:59', '2026-10-05 16:24:59', '2026-10-05 16:29:07'),
(143, 1, '50650355e4e67a137dbfbad085bc11fb07a0f3a9917fb5f9a860691b51ab39c4', '2026-10-06 00:44:10', '2026-10-05 16:44:10', '2026-10-05 16:44:14'),
(144, 1, '58ac2a8f18c483012844be8be0520552e4df3af2163475d4a32a31333ec6f6a7', '2026-10-06 00:44:21', '2026-10-05 16:44:21', '2026-10-05 16:47:10'),
(145, 1, 'ab8b46fc9d3ccb2fca7269319f53ca5fe6f3dab8ef4966e11eef6bd4437cd17c', '2026-10-06 00:47:22', '2026-10-05 16:47:22', NULL),
(146, 1, 'a252add6aff99bfc585cdf015fcdddf6f2abd869099fdafafae096bd5554c883', '2026-10-07 14:12:43', '2026-10-07 06:12:43', '2026-10-07 06:12:57'),
(147, 1, '75be61585faef5aeb6c5915a2a389e1656998c5332b944eff0641f0eb11bc46a', '2026-10-07 14:18:29', '2026-10-07 06:18:29', '2026-10-07 06:50:58'),
(148, 5, 'e266c26a2d4f6ed1ac214ff8dc8bd28426e93ee29ad05c8d188e4ead262d3904', '2026-10-07 14:51:06', '2026-10-07 06:51:06', '2026-10-07 07:31:25'),
(149, 1, '74800fdeb91a0ee754f412f0b299a27e9938119ec01df219ca12ddb17653795d', '2026-10-07 15:31:43', '2026-10-07 07:31:43', '2026-10-07 07:38:23'),
(150, 1, 'd81461d2449417e59468c3c5b7b5f2f783454456e4998ea49f399f1465b8d7db', '2026-10-07 15:38:33', '2026-10-07 07:38:33', '2026-10-07 07:40:43'),
(151, 1, 'd3a073201c4870a43e6f7cefb3b028e95fd705030859de05c9fa68dbc6351979', '2026-10-07 15:40:54', '2026-10-07 07:40:54', '2026-10-07 07:45:29'),
(152, 5, 'a7e9a246876c9975c3fa922e280c671a1ce6495491abd432b7f99f0499a87d51', '2026-10-07 15:45:34', '2026-10-07 07:45:34', '2026-10-07 07:47:54'),
(153, 4, 'b929a52e031ef0c487dd1acea21f7fb0608a656fbd12e1dd2d22c8181230c1c9', '2026-10-07 15:47:59', '2026-10-07 07:47:59', '2026-10-07 08:25:39'),
(154, 1, 'f68b619783d79477d3c93db8e643015805ae08bcbae66f75b646b833beb85956', '2026-10-07 15:58:44', '2026-10-07 07:58:44', '2026-10-07 07:59:42'),
(155, 4, '5fe0225b807095efdd83686fddab5bfbcc472a086d7fc5e8b6b070fe74f18161', '2026-10-07 15:59:47', '2026-10-07 07:59:47', '2026-10-07 09:33:17'),
(156, 5, '8b8992b08cf09aea90487e9e46a38f1ea1250974c7a67f65fe5ede9b8b72c59d', '2026-10-07 16:25:47', '2026-10-07 08:25:47', '2026-10-07 09:52:45'),
(157, 5, 'b4d04ce466b70ea47b22c497d50602f38cdb40498bc8495a4fe049eb1d026ac4', '2026-10-07 17:33:26', '2026-10-07 09:33:26', '2026-10-07 13:10:20'),
(158, 4, '4685e4305daecd8843bd18b83e0d7fd51fd811755733d3a399fa21d60edc2aa3', '2026-10-07 17:52:49', '2026-10-07 09:52:49', '2026-10-07 09:54:50'),
(159, 5, '2bd62142fbea436c1af2743abf91f74662931e16f63e5d00ab55e6c1500025b0', '2026-10-07 17:54:54', '2026-10-07 09:54:54', '2026-10-07 10:20:48'),
(160, 4, '808adc97f7bbadb2d00cf72934214d90e51bcf205cacfbfcf5e892d0098795bd', '2026-10-07 18:20:52', '2026-10-07 10:20:52', '2026-10-07 10:29:15'),
(161, 1, '04ddf214440259fc3db2c6a9467d40165d637c34a0c9622dc925646ae5b027a7', '2026-10-07 18:32:48', '2026-10-07 10:32:48', '2026-10-07 10:32:53'),
(162, 6, 'f9b281c98e19725aaff85ca03a7cc4011481997f348bfb9d8366d5f755663536', '2026-10-07 18:32:58', '2026-10-07 10:32:58', '2026-10-07 10:33:07'),
(163, 1, 'b0ddc7b4a7ea124a9bf71fce3c3e378731e87ad2593e999d910fa2a11e47def0', '2026-10-07 18:33:13', '2026-10-07 10:33:13', '2026-10-07 10:33:30'),
(164, 6, 'ae75bcff647025dd8576e2570f83f5a2c5dc588e6e5a232305959bbb52871091', '2026-10-07 18:33:35', '2026-10-07 10:33:35', '2026-10-07 11:13:28'),
(165, 5, '1b1bbc0aea8f9fde30695993b9c4e5696c91d354935b483f8acdd917a1705dbc', '2026-10-07 19:13:39', '2026-10-07 11:13:39', '2026-10-07 11:13:47'),
(166, 6, '8085bf3b75a2a2725ccf720f7a39e577c920be0affe868e5d82d994b255a1450', '2026-10-07 19:14:08', '2026-10-07 11:14:08', '2026-10-07 11:19:50'),
(167, 5, '24a4726c42d8153bd8193f6109db2c0b1dcc3a5231152782232998a85ca3de53', '2026-10-07 19:19:55', '2026-10-07 11:19:55', '2026-10-07 11:20:17'),
(168, 4, '6842290993637f3a80ee1288aab4bc3c826dad338435ff81192b8b782fa45584', '2026-10-07 19:20:21', '2026-10-07 11:20:21', '2026-10-07 11:20:44'),
(169, 6, '1117369c343cf24e8ec367d3100a85e5a72e9af2f18a3127d4b624bcd0ee437e', '2026-10-07 19:20:50', '2026-10-07 11:20:50', '2026-10-07 14:08:21'),
(170, 1, '5620d304b69c2a67890e8e77cca69490642e941234a0fd357a6e8676f84c0079', '2026-10-07 21:10:24', '2026-10-07 13:10:24', '2026-10-07 13:11:36'),
(171, 4, '813b202c5b3b5e16d789bfef5d23957471a5171422b496733fc081381f3ddbf6', '2026-10-07 21:11:42', '2026-10-07 13:11:42', '2026-10-07 13:12:23'),
(172, 1, 'df3404b8fc0b9b3c5471830f10715892b14d22e13bbdb0631cc93574febf643d', '2026-10-07 21:12:26', '2026-10-07 13:12:26', NULL),
(173, 4, '54ddd4bd8158eebf82656a1bef17ce53fd67b95de5a5a8483bc64732061197d3', '2026-10-07 22:08:26', '2026-10-07 14:08:26', '2026-10-07 14:10:29'),
(174, 5, '3019f7d349c8ec0496a67fbc4cfe033a0d7274453001664ed98e3642b72399b1', '2026-10-07 22:10:40', '2026-10-07 14:10:40', '2026-10-07 14:12:24'),
(175, 6, '72d445793c47943f0ede1fab8d64835310736493a957d7490ad8d3fa535c4219', '2026-10-07 22:12:29', '2026-10-07 14:12:29', '2026-10-07 14:13:29'),
(176, 4, '6a9f26b0f612df626ace5e8b77f26132a068aff315bbbe58a226fbfea0c4e41e', '2026-10-07 22:13:33', '2026-10-07 14:13:33', '2026-10-07 14:13:45'),
(177, 6, '740805db17df5a09e33d2c5aca6a021dd4030de889eea342988a3b92a7ae112b', '2026-10-07 22:13:49', '2026-10-07 14:13:49', '2026-10-07 14:14:03'),
(178, 5, '57c0cb9b6e33d76fe3152f747e65fdaf44bdbbd4b75de5e1412a228d4e4d9857', '2026-10-07 22:14:07', '2026-10-07 14:14:07', '2026-10-07 14:28:18'),
(179, 4, 'c63a42773cfbfa3c34ef234a63c55a4ce2a9200e6218f78f3f5d97676f554e0c', '2026-10-07 22:28:22', '2026-10-07 14:28:22', '2026-10-07 14:28:55'),
(180, 5, '8ce1bbc1448b476c2b2ed821246a9eb6279a4a57af77871cb34335e654cd8a8c', '2026-10-07 22:28:59', '2026-10-07 14:28:59', '2026-10-07 14:29:20'),
(181, 4, 'e2291ca97beba2005741484a0f1cf3eb61ccb82ea6ff49a1f3d073fe7c7f41aa', '2026-10-07 22:29:30', '2026-10-07 14:29:30', '2026-10-07 14:30:19'),
(182, 5, '901747510c3004a3f9c7c1e6c20d7ab4f5784a27e1153548a1269a88d6596587', '2026-10-07 22:30:23', '2026-10-07 14:30:23', '2026-10-07 15:06:27'),
(183, 5, '942fcc29ec817601bc5a53c3b76e0379f34ccd861a21c7ca9c08afa5f457b302', '2026-10-07 23:06:32', '2026-10-07 15:06:32', '2026-10-07 15:14:39'),
(184, 6, '0bef8e5b22f4187148df1fc71d2c4c200693f65a827ac9baf7acf68487f18483', '2026-10-07 23:14:43', '2026-10-07 15:14:43', '2026-10-07 15:15:35'),
(185, 4, '58401f0694a28742945fbb9efe773c3842b0aa65ad627be7c76c284bc21109f4', '2026-10-07 23:15:39', '2026-10-07 15:15:39', '2026-10-07 15:15:54'),
(186, 6, 'a43e915d5ab504e8af21393ac8aa0c5b29d0fae68939051c74329f8d73cd9baf', '2026-10-07 23:15:59', '2026-10-07 15:15:59', '2026-10-07 15:16:05'),
(187, 5, '44ac4cc56ab0f9d54fcbd22ac031e09c7d493ebe93ff8119a5b1d4a7c1bce6f9', '2026-10-07 23:16:09', '2026-10-07 15:16:09', '2026-10-07 15:18:14'),
(188, 6, 'c84d13f7f9eae90fdf291839f8f562653f79a5153c79eeb7de73b8c6d9578c47', '2026-10-08 16:13:33', '2026-10-08 08:13:33', '2026-10-08 08:14:19'),
(189, 5, '6ce85fdd71db0995e48db356569b4d4a40cf1b3cd18f3980f769f1605856fb0b', '2026-10-08 16:14:23', '2026-10-08 08:14:23', '2026-10-08 08:14:35'),
(190, 4, '43cf41751837481f84b7a72f234c7bd49821986254c99ecabb8c2c696b811b56', '2026-10-08 16:14:39', '2026-10-08 08:14:39', '2026-10-08 10:24:23'),
(191, 5, 'b0f8b3a3dc2f556635f646f7b0cae0989b6ee1370b7efc386b18bc6884b67683', '2026-10-08 18:24:27', '2026-10-08 10:24:27', '2026-10-08 10:24:36'),
(192, 6, '8474c182d8403e4a7664f885f520c7a0e7d5c18d968a59a14ecc8b4a9c90197c', '2026-10-08 18:24:41', '2026-10-08 10:24:41', '2026-10-08 10:25:31'),
(193, 5, '4712b88af69a3be26760b502976b8c2e8ddbb5cf21da148889389374558ed03a', '2026-10-08 18:25:37', '2026-10-08 10:25:37', '2026-10-08 10:26:13'),
(194, 4, 'd9ba59848a4258236dc5974a91ee53ef587575a9b1f6c7d2a38a55098dfd3698', '2026-10-08 18:26:18', '2026-10-08 10:26:18', '2026-10-08 10:28:16'),
(195, 6, 'c1891d92e5be511a3da1484ddd8e1265872117ed327e136e23b4ed70f565a991', '2026-10-08 18:28:22', '2026-10-08 10:28:22', '2026-10-08 10:29:08'),
(196, 5, 'e2a0b3cd7b0dd715ec6ab2e22f0b9ca489c8d86171b2e1e6c99c60acc248a929', '2026-10-08 18:29:17', '2026-10-08 10:29:17', '2026-10-08 16:46:37'),
(197, 4, '309b44fa0ec12ff04de5c5014691ee9ec7e4479ef251f7f4eae3a33a0336f87b', '2026-10-09 00:46:41', '2026-10-08 16:46:41', '2026-10-08 16:49:19'),
(198, 5, 'f5cdcfb7930ded207c98715267cb5dfa8d9a173207c5d0623b8be3e43ac319af', '2026-10-09 00:49:29', '2026-10-08 16:49:29', '2026-10-08 16:52:11'),
(199, 1, '284fa463006b6372da29cee792982a6c2d8c8b65ed865e454379063dbde4f50f', '2026-10-09 00:52:19', '2026-10-08 16:52:19', '2026-10-08 16:52:34'),
(200, 4, '24406c3d1779660ccedbd69638d359c27bb3611e2647d705e81e64c3f3daafa9', '2026-10-09 00:52:40', '2026-10-08 16:52:40', '2026-10-08 16:52:51'),
(201, 6, '4400e8d7f7545894e13e9b76582dd3280df9eab5b8c119b2729edf5649a163a3', '2026-10-09 00:53:02', '2026-10-08 16:53:02', '2026-10-08 16:53:21'),
(202, 4, 'bca1ac834550e8a683c5800d8e4c8510de8fdd1297701d8a2b1a1a1e88ec64c8', '2026-10-09 00:53:27', '2026-10-08 16:53:27', '2026-10-08 16:54:06'),
(203, 5, '85e21ffa6a7384da49c9f2e76e96314d7360fc87654734f6c0b51af4bcacdb69', '2026-10-09 00:54:11', '2026-10-08 16:54:11', NULL),
(204, 6, '82102fa7d234354dbb07488d5f26bd806d06904200a7865f9f3ff3678267f9dd', '2026-10-09 17:08:56', '2026-10-09 09:08:56', '2026-10-09 09:23:27'),
(205, 4, '2cb531fb402bf6af68536ccbcb33ffd749cbea280e48e3cf25cf5eadab9af258', '2026-10-09 17:23:32', '2026-10-09 09:23:32', '2026-10-09 09:24:32'),
(206, 6, '6d80ba5d24f15bf68c1055bb2b7899d3ad7e25b41a43a9f68cc916ffd727b717', '2026-10-09 17:24:39', '2026-10-09 09:24:39', '2026-10-09 09:25:03'),
(207, 5, '4bf4da7c1f1f5d71e6531a62542b75049cf16905fa459f795d1ac048fce2addf', '2026-10-09 17:25:08', '2026-10-09 09:25:08', '2026-10-09 09:27:33'),
(208, 6, 'f82c6a2a03967e8d94bafcc0dcd1a15ae5e91de5743bcaa1d55af3668aece9b2', '2026-10-09 17:27:37', '2026-10-09 09:27:37', '2026-10-09 09:27:39'),
(209, 5, '0f951327831bb2175428ab7d9cf71cad767458f4ef5723029a89b1574db2d84c', '2026-10-09 17:27:43', '2026-10-09 09:27:43', '2026-10-09 09:28:47'),
(210, 6, '2f835216d0e63be327de99eb2a4a8f979bfbde1f0d01e0efdbfb240d1ec6695a', '2026-10-09 17:28:54', '2026-10-09 09:28:54', '2026-10-09 09:29:17'),
(211, 4, '3b7fecf9bdc7fa3a672dbeff689be8e1826733d2864f00703a39c1ed49fd07d8', '2026-10-09 17:29:21', '2026-10-09 09:29:21', '2026-10-09 11:45:30'),
(212, 5, 'ef9d23173614f2da656520b0e6e91199bc506c8395360ee1375606a762778b63', '2026-10-09 19:45:44', '2026-10-09 11:45:44', '2026-10-09 12:40:33'),
(213, 5, '79f1e0c110ec16a553f3bb33ccc39c0b2ccf94458e9dfaa08e92948ef78a3f86', '2026-10-09 20:40:39', '2026-10-09 12:40:39', '2026-10-09 13:05:23'),
(214, 6, '6ce54eddb62c7a1b78b916af82c9f2e72381b91fe9bf80e5777c2c54c6f8c74f', '2026-10-09 21:05:28', '2026-10-09 13:05:28', '2026-10-09 13:06:08'),
(215, 5, 'be2d2814fbd27f7af993751f9fe1aed0d75f3011c99cf561e36c7068ba50b0c3', '2026-10-09 21:06:14', '2026-10-09 13:06:14', '2026-10-09 13:06:31'),
(216, 4, 'e27f75dd09264b4467cce61b35bf6aad895c806c97c2841a7f395ae866a79413', '2026-10-09 21:06:36', '2026-10-09 13:06:36', '2026-10-09 13:08:13'),
(217, 1, 'fca1e60218b52b6f0931d78a4022b9972ca7db333921b7404bc5465289c1ddea', '2026-10-09 21:08:18', '2026-10-09 13:08:18', '2026-10-09 13:08:59'),
(218, 5, 'b31103680b66a52169e5a9c821dc41a282ea9e12221464e16c217553c47d2e88', '2026-10-09 21:09:08', '2026-10-09 13:09:08', NULL);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `concern_attachments`
--
ALTER TABLE `concern_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `concern_comments`
--
ALTER TABLE `concern_comments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `concern_status_attachments`
--
ALTER TABLE `concern_status_attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `concern_status_history`
--
ALTER TABLE `concern_status_history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=219;

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
