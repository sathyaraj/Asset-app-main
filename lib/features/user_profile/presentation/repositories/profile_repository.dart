import 'package:dio/dio.dart';

import '../models/user_profile.dart';
import 'package:assets_app/core/utils/role_model.dart';
import 'package:assets_app/core/utils/api_service.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String employeeId);

  Future<UserProfile> updateProfile(UserProfile profile);
}

// ============================================================
// API PROFILE REPOSITORY
// ============================================================

class ApiProfileRepository implements ProfileRepository {
  final ApiService apiService;

  ApiProfileRepository({required this.apiService});

  // ============================================================
  // GET PROFILE
  // ============================================================

  @override
  Future<UserProfile> getProfile(String employeeId) async {
    final response = await apiService.getProfile();

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile response.');
    }

    if (data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Failed to load profile.');
    }

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw Exception('User data not found.');
    }

    return _fromJson(user);
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await apiService.updateProfile({
      'id': profile.id,
      'phone': profile.phoneNumber,
      'email': profile.email,
      'location': profile.location,

      // Save role VALUE
      'role': profile.role.value,
    });

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid update response.');
    }

    if (data['success'] != true) {
      throw Exception(
        data['message']?.toString() ?? 'Failed to update profile.',
      );
    }

    return profile;
  }

  // ============================================================
  // JSON -> UserProfile
  // ============================================================

  UserProfile _fromJson(Map<String, dynamic> data) {
    final roleValue = data['role']?.toString() ?? '';

    return UserProfile(
      id: data['id']?.toString() ?? '',
      fullName: data['full_name']?.toString() ?? '',

      // Dynamic role from API / DB
      role: _buildRole(data, roleValue),

      status: data['status']?.toString() ?? 'Active',
      photoUrl: data['photo_url']?.toString() ?? '',
      phoneNumber: _buildPhoneNumber(data),
      email: data['email']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      companyName: data['company_name']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      employeeId: data['employee_id']?.toString() ?? '',

      // ========================================================
      // PERMISSIONS
      // 1 = true
      // 0 = false
      // ========================================================
      canViewProfile: _permissionValue(data['can_view']),

      canCreateProfile: _permissionValue(data['can_create']),

      canUpdateProfile: _permissionValue(data['can_update']),

      canDeleteProfile: _permissionValue(data['can_delete']),

      // Settings icon visibility
      canAccessSettings: _permissionValue(data['can_view']),

      // Profile edit permission
      canEditProfile: _permissionValue(data['can_update']),
    );
  }

  // ============================================================
  // PERMISSION VALUE
  // ============================================================

  bool _permissionValue(dynamic value) {
    return value == 1 || value == '1' || value == true;
  }

  // ============================================================
  // BUILD ROLE
  // ============================================================

  RoleModel _buildRole(Map<String, dynamic> data, String roleValue) {
    final roleData = data['role_data'];

    // If API returns complete role object
    if (roleData is Map) {
      return RoleModel.fromJson(Map<String, dynamic>.from(roleData));
    }

    // If API returns only role value
    // Example: cafm_manager

    return RoleModel(id: 0, name: roleValue, value: roleValue, isActive: true);
  }

  // ============================================================
  // PHONE NUMBER
  // ============================================================

  String _buildPhoneNumber(Map<String, dynamic> data) {
    final phone = data['phone']?.toString() ?? '';

    final countryCode = data['country_code']?.toString() ?? '';

    if (phone.isEmpty) {
      return '';
    }

    if (countryCode.isEmpty) {
      return phone;
    }

    return '$countryCode $phone';
  }
}
