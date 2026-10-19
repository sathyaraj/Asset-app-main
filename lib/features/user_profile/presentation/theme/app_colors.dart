import 'package:flutter/material.dart';
import 'package:assets_app/core/utils/app_colors.dart' as core;

/// Unified theme - delegates to core AppColors to avoid drift.
/// Keeps legacy names for backward compat.
class AppColors {
  AppColors._();
  // Core delegates
  static const Color background = core.AppColors.background;
  static const Color cardBackground = core.AppColors.cardBackground;
  static const Color cardWhite = core.AppColors.cardBackground;
  static const Color primary = core.AppColors.primary;
  static const Color white = core.AppColors.white;
  static const Color textPrimary = core.AppColors.textPrimary;
  static const Color textSecondary = core.AppColors.textSecondary;
  static const Color success = core.AppColors.success;
  static const Color warning = core.AppColors.warning;
  static const Color error = core.AppColors.error;
  static const Color activeGreen = core.AppColors.activeGreen;
  static const Color activeGreenText = core.AppColors.activeGreenText;
  static const Color maintenanceOrange = core.AppColors.maintenanceOrange;
  static const Color maintenanceOrangeText = core.AppColors.maintenanceOrangeText;
  static const Color storedGrey = core.AppColors.storedGrey;
  static const Color storedGreyText = core.AppColors.storedGreyText;
  // Legacy aliases
  static const Color primaryNavy = core.AppColors.cardBackground;
  static const Color primaryBlue = core.AppColors.primary;
  static const Color iconChipBg = Color(0xFFE8EEFB);
  static const Color textLink = Color(0xFFFFFFFF);
  static const Color activeGreenBg = core.AppColors.activeGreen;
  static const Color activeGreenDot = core.AppColors.activeGreenText;
  static const Color errorBg = Color(0xFFFCE4E4);
  static const Color errorText = Color(0xFFE04B4B);
  static const Color divider = Color(0xFFEDEFF3);
}