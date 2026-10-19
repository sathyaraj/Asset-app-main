import 'package:flutter/material.dart';

class PagePermission {
  final int pageId;
  final String pageName;
  final String pageKey;
  final IconData icon;

  bool canView;
  bool canCreate;
  bool canUpdate;
  bool canDelete;

  PagePermission({
    required this.pageId,
    required this.pageName,
    required this.pageKey,
    required this.icon,
    this.canView = false,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  factory PagePermission.fromJson(Map<String, dynamic> json) {
    return PagePermission(
      // Supports both:
      // "id"       -> my_page.php
      // "page_id"  -> permissions.php
      pageId:
          int.tryParse((json['page_id'] ?? json['id'] ?? '0').toString()) ?? 0,

      pageName: json['page_name']?.toString() ?? '',

      pageKey: json['page_key']?.toString() ?? '',

      icon: _getIcon(json['icon']?.toString() ?? ''),

      canView: _toBool(json['can_view']),
      canCreate: _toBool(json['can_create']),
      canUpdate: _toBool(json['can_update']),
      canDelete: _toBool(json['can_delete']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();

      return normalized == '1' || normalized == 'true';
    }

    return false;
  }

  static IconData _getIcon(String icon) {
    switch (icon) {
      case 'dashboard_outlined':
        return Icons.dashboard_outlined;

      case 'assets_outlined':
        return Icons.inventory_2_outlined;

      case 'live_tv_outlined':
        return Icons.live_tv_outlined;

      case 'qr_code_scanner':
        return Icons.qr_code_scanner;

      case 'bar_chart_outlined':
        return Icons.bar_chart_outlined;

      case 'people_outline':
        return Icons.people_outline;

      case 'list_alt_outlined':
        return Icons.list_alt_outlined;

      case 'admin_panel_settings_outlined':
        return Icons.admin_panel_settings_outlined;

      case 'location_on_outlined':
        return Icons.location_on_outlined;

      case 'person_outline':
        return Icons.person_outline;

      default:
        return Icons.apps_outlined;
    }
  }

  PagePermission copy() {
    return PagePermission(
      pageId: pageId,
      pageName: pageName,
      pageKey: pageKey,
      icon: icon,
      canView: canView,
      canCreate: canCreate,
      canUpdate: canUpdate,
      canDelete: canDelete,
    );
  }
}
