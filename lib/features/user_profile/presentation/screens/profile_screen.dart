import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/info_row.dart';
import '../widgets/info_section_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/setting_screen.dart';
import 'package:assets_app/core/utils/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String employeeId;
  final ProfileRepository repository;

  // ProfileScreen({
  //   super.key,
  //   this.employeeId = 'emp_1024',
  //   ProfileRepository? repository,
  // }) : repository = repository ?? MockProfileRepository();

  ProfileScreen({
    super.key,
    this.employeeId = 'emp_1024',
    ProfileRepository? repository,
  }) : repository =
           repository ?? ApiProfileRepository(apiService: ApiService());

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.repository.getProfile(widget.employeeId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');

        _loading = false;
      });
    }
  }

  Future<void> _openEditSheet() async {
    final current = _profile;
    if (current == null) return;

    final updated = await showDialog<UserProfile>(
      context: context,
      builder: (_) => EditProfileSheet(profile: current),
    );

    if (updated == null) return;

    setState(() => _profile = updated);
    try {
      await widget.repository.updateProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _profile = current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save changes. Please try again.'),
        ),
      );
    }
  }

  void _openSettingsPanel() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _handleLogout() {
    Navigator.of(context).pop(); // close the drawer
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false, // clears the stack so back button can't return
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: _profile != null
          ? SettingScreen(profile: _profile!, onLogout: _handleLogout)
          : null,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : !_profile!.canViewProfile
            ? const Center(
                child: Text(
                  'You do not have permission to view this page.',
                  textAlign: TextAlign.center,
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: _ProfileContent(
                  profile: _profile!,
                  onEditTap: _openEditSheet,
                  onSettingsTap: _openSettingsPanel,
                  onLogoutTap: _handleLogout,
                ),
              ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const _ProfileContent({
    required this.profile,
    required this.onEditTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(
            profile: profile,
            onEditTap: onEditTap,
            onSettingsTap: onSettingsTap,
            onLogoutTap: onLogoutTap,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoSectionCard(
                  headerIcon: Icons.person_outline_rounded,
                  title: 'Personal Information',
                  trailing: profile.canUpdateProfile
                      ? TextButton.icon(
                          onPressed: onEditTap,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        )
                      : null,
                  children: [
                    InfoRow(
                      icon: Icons.call_outlined,
                      label: 'Phone Number',
                      value: profile.phoneNumber,
                    ),
                    InfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email Address',
                      value: profile.email,
                    ),
                    InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: profile.location,
                    ),
                    InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Position',
                      value: profile.role.value,
                    ),
                  ],
                ),
                InfoSectionCard(
                  headerIcon: Icons.apartment_rounded,
                  title: 'Organization Information',
                  children: [
                    InfoRow(
                      icon: Icons.work_outline_rounded,
                      label: 'Company Name',
                      value: profile.companyName,
                    ),
                    InfoRow(
                      icon: Icons.groups_outlined,
                      label: 'Department',
                      value: profile.department,
                    ),
                    InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Employee ID',
                      value: profile.employeeId,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.errorText,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
