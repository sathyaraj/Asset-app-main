import 'package:flutter/material.dart';
//import '../models/cafm_role.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEditTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = profile.status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryNavy, AppColors.primaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile.canCreateProfile)
                IconButton(
                  onPressed: onSettingsTap,
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Settings',
                  splashRadius: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                IconButton(
                  onPressed: onLogoutTap,
                  icon: const Icon(
                    Icons.logout_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Logout',
                  splashRadius: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white24,
                backgroundImage: profile.photoUrl.isNotEmpty
                    ? NetworkImage(profile.photoUrl)
                    : null,
                child: profile.photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              if (isActive)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.activeGreenDot,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryNavy,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon(profile.role.icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  profile.role.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
