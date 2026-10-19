-- Production Grade Database Schema for Asset Management System
-- Use this script in phpMyAdmin to set up your database

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET TIME_ZONE = "+00:00";

-- --------------------------------------------------------

--
-- Table structure for table `asset_classes`
--

DROP TABLE IF EXISTS `asset_classes`;
CREATE TABLE IF NOT EXISTS `asset_classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `code` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `asset_classes`
--

INSERT IGNORE INTO `asset_classes` (`name`, `code`) VALUES
('Laptops & Computers', 'LAP'),
('Networking Equipment', 'NET'),
('Monitors & Displays', 'MON'),
('Photography Gear', 'CAM'),
('Power Systems', 'PWR');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('Admin','Staff') DEFAULT 'Staff',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT IGNORE INTO `users` (`email`, `password`, `role`) VALUES
('admin@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin'),
('staff@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Staff');
-- --------------------------------------------------------
-- Table structure for table `locations`
--
DROP TABLE IF EXISTS `locations`;
CREATE TABLE IF NOT EXISTS `locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `location_type` varchar(100) NOT NULL,
  `site_name` varchar(255) NOT NULL,
  `building_name` varchar(255) NOT NULL,
  `area_zone` varchar(100) NOT NULL,
  `floor` varchar(50) NOT NULL,
  `room_name` varchar(100) NOT NULL,
  `room_number` varchar(50) NOT NULL,
  `condition` varchar(100) NOT NULL,
  `code` varchar(50) NOT NULL,
  `criticality` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Table structure for table `dropdown_options`
--
DROP TABLE IF EXISTS `dropdown_options`;
CREATE TABLE IF NOT EXISTS `dropdown_options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(100) NOT NULL,
  `label` varchar(255) NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `dropdown_options` (`category`, `label`, `value`) VALUES
('location_type', 'Warehouse', 'Warehouse'),
('location_type', 'Office', 'Office'),
('location_type', 'Data Center', 'Data Center'),
('location_type', 'Storage', 'Storage'),
('site_name', 'Tech Park HQ', 'Tech Park HQ'),
('site_name', 'West Coast Hub', 'West Coast Hub'),
('site_name', 'Eastern Branch', 'Eastern Branch'),
('building_name', 'Tower A', 'Tower A'),
('building_name', 'Building 2', 'Building 2'),
('building_name', 'Annex C', 'Annex C'),
('area_zone', 'North Wing', 'North Wing'),
('area_zone', 'South Wing', 'South Wing'),
('area_zone', 'Central Plaza', 'Central Plaza'),
('floor', 'Floor 1', 'Floor 1'),
('floor', 'Floor 2', 'Floor 2'),
('floor', 'Basement', 'Basement'),
('room_name', 'Server Room', 'Server Room'),
('room_name', 'Main Office', 'Main Office'),
('room_name', 'Conference Room', 'Conference Room'),
('room_number', 'Room 101', 'Room 101'),
('room_number', 'Room 202', 'Room 202'),
('room_number', 'Lab 1', 'Lab 1'),
('location_condition', 'Excellent', 'Excellent'),
('location_condition', 'Good', 'Good'),
('location_condition', 'Fair', 'Fair'),
('location_condition', 'Needs Maintenance', 'Needs Maintenance'),
('location_code', 'LOC-001', 'LOC-001'),
('location_code', 'LOC-002', 'LOC-002'),
('location_code', 'LOC-003', 'LOC-003'),
('location_criticality', 'Critical', 'Critical'),
('location_criticality', 'High', 'High'),
('location_criticality', 'Medium', 'Medium'),
('location_criticality', 'Low', 'Low');

INSERT IGNORE INTO `locations` (`location_type`, `site_name`, `building_name`, `area_zone`, `floor`, `room_name`, `room_number`, `condition`, `code`, `criticality`) VALUES
('Warehouse', 'Tech Park HQ', 'Tower A', 'North Wing', 'Floor 1', 'Server Room', 'Room 101', 'Excellent', 'LOC-001', 'High'),
('Office', 'West Coast Hub', 'Building 2', 'South Wing', 'Floor 2', 'Main Office', 'Room 202', 'Good', 'LOC-002', 'Medium');

-- 11 Asset lookup tables (also in assets_setup.sql)
CREATE TABLE IF NOT EXISTS `asset_systems` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `asset_systems` (`name`) VALUES ('HVAC System'),('Electrical System'),('Fire Safety System'),('Security System'),('IT Infrastructure'),('Plumbing System'),('Lifts & Escalators'),('Building Management'),('Lighting System'),('Solar Power System'),('Water Treatment'),('Waste Management');
CREATE TABLE IF NOT EXISTS `asset_tags` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `asset_tags` (`name`) VALUES ('High Priority'),('Low Priority'),('Sensitive'),('Fragile'),('Indoor Only'),('Outdoor Rated'),('Warranty Active'),('Leased'),('Fixed Asset'),('Consumable'),('Critical Operation'),('Hazardous');
CREATE TABLE IF NOT EXISTS `asset_types` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `asset_types` (`name`) VALUES ('Hardware'),('Software'),('Furniture'),('Vehicle'),('Machinery'),('Tooling'),('Electronic'),('Appliance'),('Network Device'),('Storage Unit'),('Power Tool'),('Safety Gear');
CREATE TABLE IF NOT EXISTS `asset_groups` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `asset_groups` (`name`) VALUES ('Office Assets'),('Data Center Assets'),('Manufacturing Tools'),('Kitchen Equipment'),('Cleaning Supplies'),('Maintenance Gear'),('Transport Fleet'),('Event Hardware'),('Lab Equipment'),('Gym Assets'),('Garden Tools'),('Security Assets');
CREATE TABLE IF NOT EXISTS `asset_classifications` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `asset_classifications` (`name`) VALUES ('Class A - High Value'),('Class B - Medium Value'),('Class C - Low Value'),('Strategic'),('Operational'),('Supporting'),('Legacy'),('Next-Gen'),('Compliance Related'),('Customer Facing'),('Internal Use'),('R&D');
CREATE TABLE IF NOT EXISTS `asset_conditions` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `asset_conditions` (`name`) VALUES ('Brand New'),('Excellent'),('Good'),('Fair'),('Poor'),('Damaged'),('Under Repair'),('Refurbished'),('Obsolete'),('Non-Functional'),('Parts Only'),('End of Life');
CREATE TABLE IF NOT EXISTS `product_codes` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `product_codes` (`name`) VALUES ('PRD-X100'),('PRD-X200'),('PRD-Y300'),('PRD-Z400'),('SKU-001'),('SKU-002'),('MOD-A1'),('MOD-B2'),('ITEM-88'),('ITEM-99'),('UNIT-77'),('UNIT-66');
CREATE TABLE IF NOT EXISTS `model_types` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `model_types` (`name`) VALUES ('Standard 2024'),('Pro Edition'),('Enterprise v2'),('Compact X'),('Ruggedized'),('Slim Design'),('High-Capacity'),('Energy-Efficient'),('Base Model'),('Custom Built'),('Portable'),('Stationary');
CREATE TABLE IF NOT EXISTS `manufacturer_names` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `manufacturer_names` (`name`) VALUES ('Apple Inc.'),('Dell Technologies'),('Samsung Electronics'),('Sony Corp'),('Cisco Systems'),('HP Enterprise'),('Bosch'),('Siemens'),('LG Electronics'),('Lenovo'),('Logitech'),('Asus');
CREATE TABLE IF NOT EXISTS `supplier_names` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `supplier_names` (`name`) VALUES ('Global Tech Logistics'),('Prime IT Solutions'),('Office Depot'),('Amazon Business'),('B2B Electronics'),('Tech Wholesale Co.'),('Industrial Supply Ltd'),('Reliable Parts Inc'),('Direct Source'),('Modern Vendor'),('Elite Partners'),('Value Added Reseller');
CREATE TABLE IF NOT EXISTS `cost_center_names` (`id` int(11) NOT NULL AUTO_INCREMENT, `name` varchar(255) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO `cost_center_names` (`name`) VALUES ('Administration'),('Information Technology'),('Human Resources'),('Finance Dept'),('Operations West'),('Operations East'),('Marketing & Sales'),('Research & Dev'),('Maintenance Unit'),('Quality Control'),('Customer Support'),('Logistics Hub');

-- --------------------------------------------------------


--
-- Table structure for table `assets`
--

DROP TABLE IF EXISTS `assets`;
CREATE TABLE IF NOT EXISTS `assets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `location_id` int(11) DEFAULT NULL,
  `asset_code` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `quantity` int(11) DEFAULT 1,
  `system` varchar(255) DEFAULT NULL,
  `tag` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `asset_name` varchar(255) NOT NULL,
  `group_name` varchar(255) DEFAULT NULL,
  `classification` varchar(255) DEFAULT NULL,
  `asset_condition` varchar(255) DEFAULT NULL,
  `product_code` varchar(255) DEFAULT NULL,
  `model_type` varchar(255) DEFAULT NULL,
  `manufacturer` varchar(255) DEFAULT NULL,
  `purchase_date` date DEFAULT NULL,
  `purchase_cost` decimal(15,2) DEFAULT NULL,
  `supplier` varchar(255) DEFAULT NULL,
  `cost_center` varchar(255) DEFAULT NULL,
  `comments` text DEFAULT NULL,
  `status` enum('ACTIVE','MAINTENANCE','STORED','DISPOSED') DEFAULT 'ACTIVE',
  `installed_time` varchar(50) DEFAULT NULL,
  `visual_inspection` text DEFAULT NULL,
  `image_base64` longtext DEFAULT NULL,
  `image_name` varchar(255) DEFAULT NULL,
  `image_taken_at` datetime DEFAULT NULL,
  `warranty_expiry_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_asset_code` (`asset_code`),
  KEY `idx_location_id` (`location_id`),
  CONSTRAINT `fk_assets_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Seed some initial assets
--

INSERT INTO `assets` (`asset_name`, `asset_code`, `description`, `quantity`, `system`, `tag`, `type`) VALUES
('MacBook Pro 16"', 'AST-001', 'M3 Max, 64GB RAM', 1, 'IT Infrastructure', 'High Priority', 'Hardware'),
('Office Chair', 'AST-002', 'Ergonomic Mesh Chair', 10, 'Furniture', 'Low Priority', 'Furniture');

COMMIT;
