-- Location Management System Setup
-- TABLE: locations
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

-- TABLE: dropdown_options
CREATE TABLE IF NOT EXISTS `dropdown_options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(100) NOT NULL,
  `label` varchar(255) NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- SEED DATA for Dropdowns
INSERT INTO `dropdown_options` (`category`, `label`, `value`) VALUES
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
('location_criticality', 'Low', 'Low'),

('asset_category', 'Electronics', 'Electronics'),
('asset_category', 'Furniture', 'Furniture'),
('asset_category', 'IT Infrastructure', 'IT Infrastructure'),

('asset_name', 'MacBook Pro', 'MacBook Pro'),
('asset_name', 'Dell Monitor', 'Dell Monitor'),
('asset_name', 'Cisco Switch', 'Cisco Switch');

-- Seed some initial locations
INSERT INTO `locations`
  (`location_type`, `site_name`, `building_name`, `area_zone`, `floor`, `room_name`, `room_number`, `condition`, `code`, `criticality`)
VALUES
('Warehouse', 'Tech Park HQ', 'Tower A', 'North Wing', 'Floor 1', 'Server Room', 'Room 101', 'Excellent', 'LOC-001', 'High'),
('Office', 'West Coast Hub', 'Building 2', 'South Wing', 'Floor 2', 'Main Office', 'Room 202', 'Good', 'LOC-002', 'Medium');