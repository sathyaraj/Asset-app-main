import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:assets_app/core/utils/page_permission.dart';
import 'package:assets_app/core/utils/role_model.dart';

// ============================================================
// API SERVICE PROVIDER
// ============================================================

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// ============================================================
// API SERVICE
// ============================================================

class ApiService {
  late final Dio _dio;

  // ==========================================================
  // SECURE STORAGE
  // ==========================================================

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  ApiService() {
    _dio = Dio(
      BaseOptions(
        // Production:
        // baseUrl: 'https://test.efficientgroupdubai.com/',

        // Android Emulator:
        // baseUrl: 'http://10.0.2.2/backend/',
        baseUrl:
            'https://zap-glitch-saturday.ngrok-free.dev/Asset-app-main/backend/',

        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),

        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },

        // Only 2xx responses are considered successful.
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    // ========================================================
    // JWT INTERCEPTOR
    // ========================================================

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Read JWT token from secure storage.
            final token = await _storage.read(key: 'jwt_token');

            // Don't send JWT to login endpoint.
            if (token != null &&
                token.isNotEmpty &&
                !options.path.contains('auth/login.php')) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            debugPrint('JWT token read error: $e');
          }

          handler.next(options);
        },

        // ======================================================
        // RESPONSE
        // ======================================================
        onResponse: (response, handler) {
          handler.next(response);
        },

        // ======================================================
        // ERROR
        // ======================================================
        // onError: (DioException error, handler) {
        //   handler.next(error);
        // },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          final message = responseData is Map
              ? responseData['message']?.toString().toLowerCase() ?? ''
              : '';

          if (statusCode == 401 &&
              (message.contains('token has expired') ||
                  message.contains('token expired'))) {
            await _storage.delete(key: 'jwt_token');

            debugPrint('Expired JWT token cleared. Please login again.');
          }

          handler.next(error);
        },
      ),
    );

    // ========================================================
    // DEBUG LOGGING
    // ========================================================

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,

          // NOTE:
          // requestBody is enabled only for debugging.
          // Be careful with passwords/sensitive data.
          requestBody: true,

          responseBody: true,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  // Future<Response> login(String email, String password) async {
  //   try {
  //     final response = await _dio.post(
  //       'auth/login.php',
  //       data: {'email': email, 'password': password},
  //     );

  //     // ========================================================
  //     // SAVE JWT TOKEN
  //     // ========================================================

  //     final data = response.data;

  //     if (data is Map<String, dynamic>) {
  //       final token = data['token'];

  //       if (token != null && token.toString().isNotEmpty) {
  //         await _storage.write(key: 'jwt_token', value: token.toString());
  //       }
  //     }

  //     return response;
  //   } on DioException catch (e) {
  //     throw Exception(_getErrorMessage(e));
  //   }
  // }

  Future<Response> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'auth/login.php',
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid login response from server.');
      }

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Login failed.');
      }

      final token = data['token'];

      if (token == null || token.toString().trim().isEmpty) {
        throw Exception('Login succeeded but the server returned no token.');
      }

      // Save the new token before allowing navigation.
      await _storage.write(key: 'jwt_token', value: token.toString());

      // Verify that the token was saved successfully.
      final savedToken = await _storage.read(key: 'jwt_token');

      if (savedToken != token.toString()) {
        throw Exception('Unable to save the login token securely.');
      }

      debugPrint('Login successful. JWT token saved securely.');

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // LOGOUT
  // =========================================================== =

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // ============================================================
  // GET JWT TOKEN
  // ============================================================

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // USER METHODS
  // ============================================================

  // ------------------------------------------------------------
  // CREATE USER
  // ------------------------------------------------------------

  Future<Response> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('auth/create.php', data: userData);

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ------------------------------------------------------------
  // GET PROFILE
  // ------------------------------------------------------------

  Future<Response> getProfile() async {
    try {
      final response = await _dio.get('auth/profile.php');

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ------------------------------------------------------------
  // UPDATE PROFILE
  // ------------------------------------------------------------

  Future<Response> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.put(
        'auth/profile_update.php',
        data: profileData,
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // ASSET METHODS
  // ============================================================

  // ------------------------------------------------------------
  // GET ASSETS
  // ------------------------------------------------------------

  Future<Response> getAssets() async {
    try {
      final response = await _dio.get('assets/list.php');

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ------------------------------------------------------------
  // CREATE ASSET
  // ------------------------------------------------------------

  Future<Response> createAsset(Map<String, dynamic> assetData) async {
    try {
      final response = await _dio.post('assets/create.php', data: assetData);

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ------------------------------------------------------------
  // UPDATE ASSET
  // ------------------------------------------------------------

  // Future<Response> updateAsset(
  //   Map<String, dynamic> assetData,
  // ) async {
  //   try {
  //     final response = await _dio.post(
  //       'assets/update.php',
  //       data: assetData,
  //     );

  //     return response;
  //   } on DioException catch (e) {
  //     throw Exception(
  //       _getErrorMessage(e),
  //     );
  //   }
  // }

  Future<Response> updateAsset(Map<String, dynamic> assetData) async {
    try {
      final response = await _dio.put('assets/update.php', data: assetData);

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ------------------------------------------------------------
  // DELETE ASSET
  // ------------------------------------------------------------

  Future<Response> deleteAsset(int id) async {
    try {
      final response = await _dio.post('assets/delete.php', data: {'id': id});

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Future<Response> getDashboardStats() async {
    try {
      final response = await _dio.get('dashboard/get_stats.php');

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // LOCATION METHODS
  // ============================================================

  // ------------------------------------------------------------
  // GET LOCATIONS
  // ------------------------------------------------------------

  Future<Response> getLocations() async {
    try {
      final response = await _dio.get('locations/list.php');

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ------------------------------------------------------------
  // CREATE LOCATION
  // ------------------------------------------------------------

  Future<Response> createLocation(Map<String, dynamic> locationData) async {
    try {
      final response = await _dio.post(
        'locations/create.php',
        data: locationData,
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // GENERAL DROPDOWNS
  // ============================================================

  // ============================================================
  // DROPDOWN OPTIONS
  // ============================================================

  Future<Map<String, dynamic>> getDropdownOptions({
    String? search,
    String? category,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        'dropdowns/list.php',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,

          if (category != null && category.isNotEmpty) 'category': category,

          'page': page,
          'limit': limit,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // CREATE DROPDOWN OPTION
  // ============================================================

  Future<Map<String, dynamic>> createDropdownOption(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('dropdowns/create.php', data: data);

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // UPDATE DROPDOWN OPTION
  // ============================================================

  Future<Map<String, dynamic>> updateDropdownOption(
    dynamic id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        'dropdowns/update.php?id=$id',
        data: data,
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // DELETE DROPDOWN OPTION
  // ============================================================

  Future<Map<String, dynamic>> deleteDropdownOption(dynamic id) async {
    try {
      final response = await _dio.delete('dropdowns/delete.php?id=$id');

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // ASSET DROPDOWNS
  // ============================================================

  Future<Response> getAssetDropdowns() async {
    try {
      final response = await _dio.get('assets/dropdowns.php');

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // ASSET SCANNING
  // ============================================================

  Future<Response> scanLookup(String code) async {
    try {
      final response = await _dio.get(
        'scan/scan_lookup.php',
        queryParameters: {'code': code},
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // BULK CREATE ASSETS
  // ============================================================

  Future<Response> bulkCreateAssets(List<Map<String, dynamic>> assets) async {
    try {
      final response = await _dio.post(
        'assets/bulk_create.php',
        data: {'assets': assets},
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }
  // ============================================================
  // BULK CREATE LOCATIONS
  // ============================================================

  Future<Response> bulkCreateLocations(
    List<Map<String, dynamic>> locations,
  ) async {
    try {
      final response = await _dio.post(
        'locations/bulk_create.php',
        data: {'locations': locations},
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ------------------------------------------------------------
  // GET USERS
  // ------------------------------------------------------------

  Future<Response> getUsers({
    String? search,
    String? role,
    String? department,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'limit': limit,
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      if (role != null && role.trim().isNotEmpty) {
        queryParameters['role'] = role.trim();
      }

      if (department != null && department.trim().isNotEmpty) {
        queryParameters['department'] = department.trim();
      }

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status.trim();
      }

      final response = await _dio.get(
        'auth/users.php', // ✅ FIXED
        queryParameters: queryParameters,
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }
  // ------------------------------------------------------------
  // UPDATE USER
  // ------------------------------------------------------------

  Future<Response> updateUser({
    required String id,
    required String fullName,
    required String employeeId,
    required String email,
    required String phone,
    required String department,
    required String designation,
    required String employeeType,
    required String location,
    required String role,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        'auth/update.php',
        data: {
          'id': id,
          'full_name': fullName,
          'employee_id': employeeId,
          'email': email,
          'phone': phone,
          'department': department,
          'designation': designation,
          'employee_type': employeeType,
          'location': location,
          'role': role,
          'status': status,
        },
      );

      return response;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  //=============================================================
  //Permission role pages
  //=============================================================
  Future<List<PagePermission>> getMyPages() async {
    try {
      final response = await _dio.get('pages/my_page.php');
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid server response');
      }

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Failed to load pages');
      }

      final pages = data['pages'] as List<dynamic>? ?? [];

      return pages
          .map((e) => PagePermission.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  //=============================================================
  //Get Role
  //=============================================================
  Future<List<RoleModel>> getRoles() async {
    try {
      debugPrint('GET ROLES: Calling roles/list.php');

      final response = await _dio.get('roles/list.php');

      debugPrint('GET ROLES STATUS: ${response.statusCode}');
      debugPrint('GET ROLES RESPONSE: ${response.data}');

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid roles response.');
      }

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Unable to load roles.');
      }

      final rawRoles = data['roles'];

      if (rawRoles is! List) {
        throw Exception('Invalid roles data received from server.');
      }

      final roles = rawRoles
          .map((e) => RoleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      debugPrint('GET ROLES SUCCESS: ${roles.length} roles');

      return roles;
    } on DioException catch (e) {
      debugPrint('========================================');
      debugPrint('GET ROLES DIO ERROR');
      debugPrint('Type: ${e.type}');
      debugPrint('Message: ${e.message}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('========================================');

      throw Exception(_getErrorMessage(e));
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('GET ROLES ERROR');
      debugPrint('Error: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('========================================');

      rethrow;
    }
  }

  //=============================================================
  //Role Permission
  //=============================================================
  Future<List<PagePermission>> getRolePermissions(int roleId) async {
    try {
      final response = await _dio.get(
        'roles/permission.php',
        queryParameters: {'role_id': roleId},
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid server response');
      }

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Failed to load permissions',
        );
      }

      final List<dynamic> pages = data['pages'] ?? [];

      return pages
          .map((e) => PagePermission.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // CREATE ROLE
  // ============================================================

  Future<RoleModel> createRole({
    required String name,
    required String value,
    bool isActive = true,
  }) async {
    try {
      final response = await _dio.post(
        'roles/create.php',
        data: {'name': name, 'value': value, 'is_active': isActive ? 1 : 0},
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid server response');
      }

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Failed to create role');
      }

      return RoleModel.fromJson(Map<String, dynamic>.from(data['role']));
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // UPDATE ROLE
  // ============================================================

  Future<RoleModel> updateRole({
    required int id,
    required String name,
    required String value,
    bool isActive = true,
  }) async {
    try {
      final response = await _dio.put(
        'roles/update.php',
        data: {
          'id': id,
          'name': name,
          'value': value,
          'is_active': isActive ? 1 : 0,
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid server response');
      }

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Failed to update role');
      }

      return RoleModel.fromJson(Map<String, dynamic>.from(data['role']));
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // DELETE ROLE
  // ============================================================

  Future<void> deleteRole(int id) async {
    try {
      final response = await _dio.delete(
        'roles/delete.php',
        queryParameters: {'id': id},
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid server response');
      }

      if (data['success'] != true) {
        throw Exception(data['message']?.toString() ?? 'Failed to delete role');
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // SAVE ROLE PERMISSIONS
  // ============================================================

  Future<void> saveRolePermissions({
    required int roleId,
    required List<PagePermission> permissions,
  }) async {
    try {
      final response = await _dio.post(
        'permissions/save.php',
        data: {
          'role_id': roleId,
          'permissions': permissions.map((permission) {
            return {
              'page_id': permission.pageId,
              'can_view': permission.canView ? 1 : 0,
              'can_create': permission.canCreate ? 1 : 0,
              'can_update': permission.canUpdate ? 1 : 0,
              'can_delete': permission.canDelete ? 1 : 0,
            };
          }).toList(),
        },
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid server response');
      }

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Failed to save role permissions',
        );
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  String _getErrorMessage(DioException e) {
    // ==========================================================
    // SERVER RESPONSE AVAILABLE
    // ==========================================================

    if (e.response != null) {
      final statusCode = e.response?.statusCode;

      final responseData = e.response?.data;

      // --------------------------------------------------------
      // Try to read PHP API message
      // --------------------------------------------------------

      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      // --------------------------------------------------------
      // HTTP 401
      // --------------------------------------------------------

      if (statusCode == 401) {
        return 'Authentication failed. Please login again.';
      }

      // --------------------------------------------------------
      // HTTP 403
      // --------------------------------------------------------

      if (statusCode == 403) {
        return 'You do not have permission to perform this action.';
      }

      // --------------------------------------------------------
      // HTTP 404
      // --------------------------------------------------------

      if (statusCode == 404) {
        return 'Requested resource was not found.';
      }

      // --------------------------------------------------------
      // HTTP 405
      // --------------------------------------------------------

      if (statusCode == 405) {
        return 'This operation is not supported by the server.';
      }

      // --------------------------------------------------------
      // HTTP 422
      // --------------------------------------------------------

      if (statusCode == 422) {
        return 'Invalid data. Please check your input.';
      }

      // --------------------------------------------------------
      // HTTP 500
      // --------------------------------------------------------

      if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
      }

      // --------------------------------------------------------
      // Other server errors
      // --------------------------------------------------------

      return 'Server error ($statusCode). Please try again.';
    }

    // ==========================================================
    // NETWORK / DIO ERRORS
    // ==========================================================

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.sendTimeout:
        return 'Request timeout while sending data.';

      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Please check your internet connection.';

      case DioExceptionType.badCertificate:
        return 'Secure connection error with the server.';

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.badResponse:
        return 'Invalid response received from the server.';

      case DioExceptionType.unknown:
        return 'Network error: ${e.message ?? 'Unknown error'}';
    }
  }
}
