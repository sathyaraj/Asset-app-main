# Asset Management System - Mini ERP

## Overview
This is a multi-user, role-based Asset Management System designed as a mobile-first mini ERP.  
The system allows managing assets, locations, dynamic forms, reports, and admin-controlled dropdowns.

## User Roles
- **Admin**: Full access, can seed dropdowns, add/remove fields, master CRUD, manage roles.
- **Staff/User**: Can view dashboard, search, manage assigned assets as per permissions.

## Modules / Screens
1. **Login**
   - User authentication (email/password)
   - Role-based access
2. **Dashboard**
   - Cards per asset class
   - Card details: asset class, asset class code, total number
   - Infinite scroll / pagination
   - Search across asset code / class code / quantity
3. **Asset Management List**
   - List all assets in card format
   - Fields per card: asset code, asset name, time, location
   - Filter & search functionality
   - Button: Create New Asset
4. **Create New Asset**
   - Radio toggle: Location / Asset
   - **Location form fields**:
     - Location type
     - Site/Project name
     - Building name / number
     - Area / Zone
     - Floor
     - Room name / number
     - Location condition
     - Location code
   - **Asset form fields**:
     - Location fields (as above)
     - Asset system/category
     - Asset type
     - Asset name
     - Asset group
     - Parent asset
     - Asset status
     - Asset ID
   - All dropdowns admin-seeded
5. **Admin Control**
   - Master CRUD for all entities
   - Add new fields dynamically
   - Seed dropdown data
   - Manage users and roles

## Features
- Multi-user with Role-Based Access Control (RBAC)
- Dynamic forms with admin-seeded dropdowns
- Pagination / infinite scroll for lists
- Search and filter capabilities
- CSV / Excel export for dashboard & assets
- Audit logs for tracking user actions

## Stack Recommendation
- **Mobile App**: Flutter + Riverpod + Dio + CSV/Excel packages
- **Backend**: PHP + MySQL (Already created the database in phpmyadmin at hostinger)
- **Authentication**: basic auth
- **Database**: Normalized relational schema with pivot tables for relationships
