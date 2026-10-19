import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assets_app/core/utils/app_colors.dart';
import 'package:assets_app/core/utils/api_service.dart';
import 'package:assets_app/core/utils/page_permission.dart';

// ============================================================
// EXISTING SCREENS
// ============================================================

import 'package:assets_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:assets_app/features/assets/presentation/screens/assets_screen.dart';
import 'package:assets_app/features/assets/presentation/screens/live_inventory_screen.dart';
import 'package:assets_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:assets_app/features/qr_scan/presentation/screens/qr_scan_screen.dart';
import 'package:assets_app/features/user_profile/presentation/screens/profile_screen.dart';

// ============================================================
// MAIN NAVIGATION SCREEN
// ============================================================

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

// ============================================================
// STATE
// ============================================================

class _MainNavigationScreenState
    extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  List<PagePermission> _pages = [];

  bool _isLoading = true;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadPages();
  }

  // ==========================================================
  // LOAD USER PAGES
  // ==========================================================

  Future<void> _loadPages() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final api = ref.read(apiServiceProvider);

      final pages = await api.getMyPages();

      if (!mounted) return;

      // Only pages where can_view = true
      final visiblePages = pages
          .where((page) => page.canView)
          .toList();

      setState(() {
        _pages = visiblePages;
        _isLoading = false;

        // Keep selected index valid
        if (_pages.isEmpty) {
          _selectedIndex = 0;
        } else if (_selectedIndex >= _pages.length) {
          _selectedIndex = 0;
        }
      });

      // Debug
      debugPrint(
        'Loaded ${_pages.length} permitted pages',
      );

      for (final page in _pages) {
        debugPrint(
          'Page: ${page.pageName} | '
          'Key: ${page.pageKey} | '
          'View: ${page.canView}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _pages = [];
        _selectedIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load menu: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // PAGE KEY -> SCREEN
  // ==========================================================

  Widget _buildScreen(String pageKey) {
    switch (pageKey) {
      // --------------------------------------------------------
      // DASHBOARD
      // --------------------------------------------------------

      case 'dashboard':
        return const DashboardScreen();

      // --------------------------------------------------------
      // ASSETS
      // --------------------------------------------------------

      case 'assets':
        return const AssetsScreen();

      // --------------------------------------------------------
      // LIVE INVENTORY
      // --------------------------------------------------------

      case 'live_inventory':
        return const LiveInventoryScreen();

      // --------------------------------------------------------
      // QR SCAN
      // --------------------------------------------------------

      case 'qr_scan':
        return const QRScanScreen();

      // --------------------------------------------------------
      // REPORTS
      // --------------------------------------------------------

      case 'reports':
        return const ReportsScreen();

      // --------------------------------------------------------
      // PROFILE
      // --------------------------------------------------------

      case 'profile':
        return ProfileScreen(
          employeeId: '',
        );

      // --------------------------------------------------------
      // USER MANAGEMENT
      // --------------------------------------------------------
      //
      // Add your UserListScreen import and screen here when needed.
      //
      // case 'user_management':
      //   return const UserListScreen();

      // --------------------------------------------------------
      // DROPDOWN OPTIONS
      // --------------------------------------------------------
      //
      // Add your DropdownOptionsScreen import and screen here.
      //
      // case 'dropdown_options':
      //   return const DropdownOptionsScreen();

      // --------------------------------------------------------
      // ROLE MANAGEMENT
      // --------------------------------------------------------
      //
      // Add your RoleManagementScreen import and screen here.
      //
      // case 'role_management':
      //   return const RoleManagementScreen();

      // --------------------------------------------------------
      // LOCATIONS
      // --------------------------------------------------------
      //
      // Add your LocationScreen import and screen here.
      //
      // case 'locations':
      //   return const LocationScreen();

      // --------------------------------------------------------
      // FALLBACK
      // --------------------------------------------------------

      default:
        return SettingScreen(
          title: _formatPageName(pageKey),
        );
    }
  }

  // ==========================================================
  // FORMAT PAGE NAME
  // ==========================================================

  String _formatPageName(String value) {
    if (value.trim().isEmpty) {
      return 'Page';
    }

    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  // ==========================================================
  // LOADING SCREEN
  // ==========================================================

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ==========================================================
  // NO PAGES SCREEN
  // ==========================================================

  Widget _buildNoPagesScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.lock_outline,
                size: 60,
                color: AppColors.textSecondary,
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'No pages available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              const Text(
                'You do not have permission to access any page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              // Retry button
              ElevatedButton(
                onPressed: _loadPages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // LOADING
    // ========================================================

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // ========================================================
    // NO PERMISSION
    // ========================================================

    if (_pages.isEmpty) {
      return _buildNoPagesScreen();
    }

    // ========================================================
    // SAFETY CHECK
    // ========================================================

    if (_selectedIndex >= _pages.length) {
      _selectedIndex = 0;
    }

    // ========================================================
    // CURRENT PAGE
    // ========================================================

    final currentPage = _pages[_selectedIndex];

    // ========================================================
    // MAIN SCAFFOLD
    // ========================================================

    return Scaffold(
      backgroundColor: AppColors.background,

      // ======================================================
      // BODY
      // ======================================================

      body: _buildScreen(
        currentPage.pageKey,
      ),

      // ======================================================
      // BOTTOM NAVIGATION
      // ======================================================

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,

          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),
          ),
        ),

        child: BottomNavigationBar(
          // --------------------------------------------------
          // SELECTED INDEX
          // --------------------------------------------------

          currentIndex: _selectedIndex,

          // --------------------------------------------------
          // ON TAP
          // --------------------------------------------------

          onTap: (index) {
            if (index < 0 || index >= _pages.length) {
              return;
            }

            setState(() {
              _selectedIndex = index;
            });
          },

          // --------------------------------------------------
          // COLORS
          // --------------------------------------------------

          backgroundColor: AppColors.background,

          selectedItemColor: AppColors.primary,

          unselectedItemColor: AppColors.textSecondary,

          // --------------------------------------------------
          // TYPE
          // --------------------------------------------------

          type: BottomNavigationBarType.fixed,

          // --------------------------------------------------
          // LABELS
          // --------------------------------------------------

          showSelectedLabels: true,

          showUnselectedLabels: true,

          selectedFontSize: 10,

          unselectedFontSize: 10,

          // --------------------------------------------------
          // DYNAMIC ITEMS
          // --------------------------------------------------

          items: _pages.map(
            (page) {
              return BottomNavigationBarItem(
                // PagePermission.icon is already IconData.
                icon: Icon(
                  page.icon,
                ),

                activeIcon: Icon(
                  page.icon,
                ),

                label: page.pageName,

                tooltip: page.pageName,
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

// ============================================================
// GENERIC FALLBACK SCREEN
// ============================================================

class SettingScreen extends StatelessWidget {
  final String title;

  const SettingScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: AppColors.primary.withValues(
                alpha: 0.5,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '$title Settings',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Under Development',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
