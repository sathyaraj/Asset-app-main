-- Asset Management System Setup
-- This script creates separate tables for each dropdown and updates the assets table

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET TIME_ZONE = "+00:00";

-- Drop existing tables if they exist
DROP TABLE IF EXISTS `asset_systems`;
DROP TABLE IF EXISTS `asset_tags`;
DROP TABLE IF EXISTS `asset_types`;
DROP TABLE IF EXISTS `asset_groups`;
DROP TABLE IF EXISTS `asset_classifications`;
DROP TABLE IF EXISTS `asset_conditions`;
DROP TABLE IF EXISTS `product_codes`;
DROP TABLE IF EXISTS `model_types`;
DROP TABLE IF EXISTS `manufacturer_names`;
DROP TABLE IF EXISTS `supplier_names`;
DROP TABLE IF EXISTS `cost_center_names`;

-- Create tables and seed data
-- 1. Asset Systems
CREATE TABLE `asset_systems` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `asset_systems` (`name`) VALUES
('HVAC System'), ('Electrical System'), ('Fire Safety System'), ('Security System'), 
('IT Infrastructure'), ('Plumbing System'), ('Lifts & Escalators'), ('Building Management'),
('Lighting System'), ('Solar Power System'), ('Water Treatment'), ('Waste Management');

-- 2. Asset Tags
CREATE TABLE `asset_tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `asset_tags` (`name`) VALUES
('High Priority'), ('Low Priority'), ('Sensitive'), ('Fragile'), 
('Indoor Only'), ('Outdoor Rated'), ('Warranty Active'), ('Leased'),
('Fixed Asset'), ('Consumable'), ('Critical Operation'), ('Hazardous');

-- 3. Asset Types
CREATE TABLE `asset_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `asset_types` (`name`) VALUES
('Hardware'), ('Software'), ('Furniture'), ('Vehicle'), 
('Machinery'), ('Tooling'), ('Electronic'), ('Appliance'),
('Network Device'), ('Storage Unit'), ('Power Tool'), ('Safety Gear');

-- 4. Asset Groups
CREATE TABLE `asset_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `asset_groups` (`name`) VALUES
('Office Assets'), ('Data Center Assets'), ('Manufacturing Tools'), ('Kitchen Equipment'), 
('Cleaning Supplies'), ('Maintenance Gear'), ('Transport Fleet'), ('Event Hardware'),
('Lab Equipment'), ('Gym Assets'), ('Garden Tools'), ('Security Assets');

-- 5. Asset Classifications
CREATE TABLE `asset_classifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `asset_classifications` (`name`) VALUES
('Class A - High Value'), ('Class B - Medium Value'), ('Class C - Low Value'), ('Strategic'), 
('Operational'), ('Supporting'), ('Legacy'), ('Next-Gen'),
('Compliance Related'), ('Customer Facing'), ('Internal Use'), ('R&D');

-- 6. Asset Conditions
CREATE TABLE `asset_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `asset_conditions` (`name`) VALUES
('Brand New'), ('Excellent'), ('Good'), ('Fair'), 
('Poor'), ('Damaged'), ('Under Repair'), ('Refurbished'),
('Obsolete'), ('Non-Functional'), ('Parts Only'), ('End of Life');

-- 7. Product Codes
CREATE TABLE `product_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `product_codes` (`name`) VALUES
('PRD-X100'), ('PRD-X200'), ('PRD-Y300'), ('PRD-Z400'), 
('SKU-001'), ('SKU-002'), ('MOD-A1'), ('MOD-B2'),
('ITEM-88'), ('ITEM-99'), ('UNIT-77'), ('UNIT-66');

-- 8. Model Types
CREATE TABLE `model_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `model_types` (`name`) VALUES
('Standard 2024'), ('Pro Edition'), ('Enterprise v2'), ('Compact X'), 
('Ruggedized'), ('Slim Design'), ('High-Capacity'), ('Energy-Efficient'),
('Base Model'), ('Custom Built'), ('Portable'), ('Stationary');

-- 9. Manufacturer Names
CREATE TABLE `manufacturer_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `manufacturer_names` (`name`) VALUES
('Apple Inc.'), ('Dell Technologies'), ('Samsung Electronics'), ('Sony Corp'), 
('Cisco Systems'), ('HP Enterprise'), ('Bosch'), ('Siemens'),
('LG Electronics'), ('Lenovo'), ('Logitech'), ('Asus');

-- 10. Supplier Names
CREATE TABLE `supplier_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `supplier_names` (`name`) VALUES
('Global Tech Logistics'), ('Prime IT Solutions'), ('Office Depot'), ('Amazon Business'), 
('B2B Electronics'), ('Tech Wholesale Co.'), ('Industrial Supply Ltd'), ('Reliable Parts Inc'),
('Direct Source'), ('Modern Vendor'), ('Elite Partners'), ('Value Added Reseller');

-- 11. Cost Center Names
CREATE TABLE `cost_center_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `cost_center_names` (`name`) VALUES
('Administration'), ('Information Technology'), ('Human Resources'), ('Finance Dept'), 
('Operations West'), ('Operations East'), ('Marketing & Sales'), ('Research & Dev'),
('Maintenance Unit'), ('Quality Control'), ('Customer Support'), ('Logistics Hub');

-- Recreate assets table with all fields (includes image + warranty for photo upload)
DROP TABLE IF EXISTS `assets`;
CREATE TABLE `assets` (
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
  KEY `idx_location_id` (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed some initial assets
INSERT INTO `assets` (`asset_name`, `asset_code`, `description`, `quantity`, `system`, `tag`, `type`, `status`) VALUES
('MacBook Pro 16"', 'AST-001', 'M3 Max, 64GB RAM', 1, 'IT Infrastructure', 'High Priority', 'Hardware', 'ACTIVE'),
('Office Chair', 'AST-002', 'Ergonomic Mesh Chair', 10, 'Furniture', 'Low Priority', 'Furniture', 'ACTIVE');

COMMIT;
