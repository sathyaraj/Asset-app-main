import 'package:assets_app/core/utils/role_model.dart';

/// Profile model for an employee (technician / manager / etc.)
class UserProfile {
  final String id;
  final String fullName;
  final RoleModel role;
  final String status;
  final String photoUrl;

  // Editable Personal Information
  final String phoneNumber;
  final String email;
  final String location;

  // Organization Information
  final String companyName;
  final String department;
  final String employeeId;

  // ============================================================
  // PROFILE PERMISSIONS
  // ============================================================

  final bool canViewProfile;
  final bool canCreateProfile;
  final bool canUpdateProfile;
  final bool canDeleteProfile;

  // Existing compatibility fields
  final bool canAccessSettings;
  final bool canEditProfile;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.status,
    required this.photoUrl,
    required this.phoneNumber,
    required this.email,
    required this.location,
    required this.companyName,
    required this.department,
    required this.employeeId,

    // Permissions
    this.canViewProfile = false,
    this.canCreateProfile = false,
    this.canUpdateProfile = false,
    this.canDeleteProfile = false,

    // Existing fields
    this.canAccessSettings = false,
    this.canEditProfile = false,
  });

  // ============================================================
  // JSON -> USER PROFILE
  // ============================================================

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',

      fullName: json['fullName']?.toString() ?? '',

      role: RoleModel.fromJson(json['role']),

      status: json['status']?.toString() ?? 'Active',

      photoUrl: json['photoUrl']?.toString() ?? '',

      phoneNumber: json['phoneNumber']?.toString() ?? '',

      email: json['email']?.toString() ?? '',

      location: json['location']?.toString() ?? '',

      companyName: json['companyName']?.toString() ?? '',

      department: json['department']?.toString() ?? '',

      employeeId: json['employeeId']?.toString() ?? '',

      // ========================================================
      // PROFILE PERMISSIONS
      // ========================================================
      canViewProfile: _toBool(json['can_view']),

      canCreateProfile: _toBool(json['can_create']),

      canUpdateProfile: _toBool(json['can_update']),

      canDeleteProfile: _toBool(json['can_delete']),

      // ========================================================
      // EXISTING COMPATIBILITY
      // ========================================================
      canAccessSettings: _toBool(json['can_view']),

      canEditProfile: _toBool(json['can_update']),
    );
  }

  // ============================================================
  // BOOL CONVERTER
  // ============================================================

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }

    return false;
  }

  // ============================================================
  // USER PROFILE -> JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'role': role.toJson(),
      'status': status,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'email': email,
      'location': location,
      'companyName': companyName,
      'department': department,
      'employeeId': employeeId,

      // Permissions
      'can_view': canViewProfile ? 1 : 0,
      'can_create': canCreateProfile ? 1 : 0,
      'can_update': canUpdateProfile ? 1 : 0,
      'can_delete': canDeleteProfile ? 1 : 0,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  UserProfile copyWith({
    String? fullName,
    RoleModel? role,
    String? status,
    String? photoUrl,
    String? phoneNumber,
    String? email,
    String? location,

    bool? canViewProfile,
    bool? canCreateProfile,
    bool? canUpdateProfile,
    bool? canDeleteProfile,

    bool? canAccessSettings,
    bool? canEditProfile,
  }) {
    return UserProfile(
      id: id,

      fullName: fullName ?? this.fullName,

      role: role ?? this.role,

      status: status ?? this.status,

      photoUrl: photoUrl ?? this.photoUrl,

      phoneNumber: phoneNumber ?? this.phoneNumber,

      email: email ?? this.email,

      location: location ?? this.location,

      companyName: companyName,

      department: department,

      employeeId: employeeId,

      // Permissions
      canViewProfile: canViewProfile ?? this.canViewProfile,

      canCreateProfile: canCreateProfile ?? this.canCreateProfile,

      canUpdateProfile: canUpdateProfile ?? this.canUpdateProfile,

      canDeleteProfile: canDeleteProfile ?? this.canDeleteProfile,

      // Existing compatibility
      canAccessSettings: canAccessSettings ?? this.canAccessSettings,

      canEditProfile: canEditProfile ?? this.canEditProfile,
    );
  }
}
