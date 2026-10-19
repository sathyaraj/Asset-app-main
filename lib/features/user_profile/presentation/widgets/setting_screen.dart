import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import 'create_user_sheet.dart';
import '../screens/userlist.dart';
import '../screens/dropdown_options_screen.dart';
import '../screens/role_management.dart';

class SettingScreen extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onLogout;

  const SettingScreen({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  // ============================================================
  // OPEN CREATE USER PAGE
  // ============================================================

  void _openCreateUser(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateUserScreen()),
    );
  }

  // ============================================================
  // OPEN USER LIST PAGE
  // ============================================================

  void _openUserList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserListScreen()),
    );
  }

  // ============================================================
  // OPEN DROPDOWN OPTIONS PAGE
  // ============================================================

  void _openDropdownOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DropdownOptionsScreen()),
    );
  }

  // ============================================================
  // OPEN ROLE MANAGEMENT PAGE
  // ============================================================

  void _openRoleManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoleManagementScreen()),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,

      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),

                    tooltip: 'Close',

                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // ==================================================
            // SETTINGS OPTIONS
            // ==================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),

                children: [
                  // ==================================================
                  // USER LIST
                  // ==================================================
                  ListTile(
                    leading: const Icon(
                      Icons.people_alt_outlined,
                      color: Colors.white,
                    ),

                    title: const Text('User List'),

                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),

                    onTap: () {
                      _openUserList(context);
                    },
                  ),

                  const Divider(height: 1),

                  // ==================================================
                  // NEW USER
                  // ==================================================
                  ListTile(
                    leading: const Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                    ),

                    title: const Text('New User'),

                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),

                    onTap: () {
                      _openCreateUser(context);
                    },
                  ),

                  const Divider(height: 1),

                  // ==================================================
                  // DROPDOWN OPTIONS
                  // ==================================================
                  ListTile(
                    leading: const Icon(
                      Icons.list_alt_outlined,
                      color: Colors.white,
                    ),

                    title: const Text('Dropdown Options'),

                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),

                    onTap: () {
                      _openDropdownOptions(context);
                    },
                  ),

                  const Divider(height: 1),

                  // ==================================================
                  // ROLE MANAGEMENT
                  // ==================================================
                  ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                    ),

                    title: const Text('Role Management'),

                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),

                    onTap: () {
                      _openRoleManagement(context);
                    },
                  ),

                  const Divider(height: 1),

                  // ==================================================
                  // LOGOUT
                  // ==================================================
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),

                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),

                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
