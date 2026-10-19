import 'package:flutter/material.dart';

/// Roles/positions used across the CAFM app. Add more values here as
/// your organization needs them — everything else (dropdown, chips,
/// icons) reads from this enum, so it's the single place to edit.
enum CafmRole {
  technician,
  cafmManager,
  supervisor,
  facilitiesExecutive,
  admin,
}

extension CafmRoleX on CafmRole {
  /// Human-readable label shown in the UI.
  String get label {
    switch (this) {
      case CafmRole.technician:
        return 'Technician';
      case CafmRole.cafmManager:
        return 'CAFM Manager';
      case CafmRole.supervisor:
        return 'Supervisor';
      case CafmRole.facilitiesExecutive:
        return 'Facilities Executive';
      case CafmRole.admin:
        return 'Administrator';
    }
  }

  /// Icon used next to the role badge on the profile card.
  IconData get icon {
    switch (this) {
      case CafmRole.technician:
        return Icons.build_outlined;
      case CafmRole.cafmManager:
        return Icons.manage_accounts_outlined;
      case CafmRole.supervisor:
        return Icons.supervisor_account_outlined;
      case CafmRole.facilitiesExecutive:
        return Icons.apartment_outlined;
      case CafmRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  /// Matches CafmRole.technician <-> "technician" when reading/writing
  /// this field from your database (Firestore/REST usually store enums
  /// as plain strings).
  String get storageValue => name;

  static CafmRole fromStorageValue(String value) {
    return CafmRole.values.firstWhere(
      (r) => r.storageValue == value,
      orElse: () => CafmRole.technician,
    );
  }
}
