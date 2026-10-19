import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assets_app/core/utils/api_service.dart';
import 'package:assets_app/core/utils/app_colors.dart';
import 'package:assets_app/core/utils/page_permission.dart';
import 'package:assets_app/core/utils/role_model.dart';

/// ===============================================================
/// STATE
/// ===============================================================

class RoleManagementState {
  final List<RoleModel> roles;
  final List<PagePermission> permissions;
  final int selectedRoleId;

  final bool isLoading;
  final bool isSaving;
  final bool isCreatingRole;
  final bool isUpdatingRole;
  final bool isDeletingRole;

  final String? errorMessage;

  const RoleManagementState({
    this.roles = const [],
    this.permissions = const [],
    this.selectedRoleId = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.isCreatingRole = false,
    this.isUpdatingRole = false,
    this.isDeletingRole = false,
    this.errorMessage,
  });

  RoleManagementState copyWith({
    List<RoleModel>? roles,
    List<PagePermission>? permissions,
    int? selectedRoleId,
    bool? isLoading,
    bool? isSaving,
    bool? isCreatingRole,
    bool? isUpdatingRole,
    bool? isDeletingRole,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoleManagementState(
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      selectedRoleId: selectedRoleId ?? this.selectedRoleId,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isCreatingRole: isCreatingRole ?? this.isCreatingRole,
      isUpdatingRole: isUpdatingRole ?? this.isUpdatingRole,
      isDeletingRole: isDeletingRole ?? this.isDeletingRole,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// ===============================================================
/// NOTIFIER
/// ===============================================================

class RoleManagementNotifier extends StateNotifier<RoleManagementState> {
  final ApiService api;

  RoleManagementNotifier(this.api) : super(const RoleManagementState()) {
    loadRoles();
  }

  /// =============================================================
  /// LOAD ROLES
  /// =============================================================

  Future<void> loadRoles() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final roles = await api.getRoles();

      if (roles.isEmpty) {
        state = state.copyWith(
          roles: [],
          permissions: [],
          selectedRoleId: 0,
          isLoading: false,
        );
        return;
      }

      // Only active roles are shown.
      final activeRoles = roles.where((role) => role.isActive).toList();

      if (activeRoles.isEmpty) {
        state = state.copyWith(
          roles: [],
          permissions: [],
          selectedRoleId: 0,
          isLoading: false,
        );
        return;
      }

      int selectedRoleId = state.selectedRoleId;

      final selectedExists = activeRoles.any(
        (role) => role.id == selectedRoleId,
      );

      if (!selectedExists) {
        selectedRoleId = activeRoles.first.id;
      }

      state = state.copyWith(
        roles: activeRoles,
        selectedRoleId: selectedRoleId,
        isLoading: true,
      );

      await _loadPermissionsForRole(selectedRoleId, showLoading: false);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
    }
  }

  /// =============================================================
  /// LOAD PERMISSIONS FOR ROLE
  /// =============================================================

  Future<void> _loadPermissionsForRole(
    int roleId, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final permissions = await api.getRolePermissions(roleId);

      state = state.copyWith(
        permissions: permissions,
        selectedRoleId: roleId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        permissions: [],
        selectedRoleId: roleId,
        isLoading: false,
        errorMessage: _cleanError(e),
      );
    }
  }

  /// =============================================================
  /// SELECT ROLE
  /// =============================================================

  Future<void> selectRole(int roleId) async {
    if (roleId == state.selectedRoleId && state.permissions.isNotEmpty) {
      return;
    }

    await _loadPermissionsForRole(roleId);
  }

  /// =============================================================
  /// UPDATE SINGLE PERMISSION
  /// =============================================================

  void updatePermission({
    required int pageId,
    required String permission,
    required bool value,
  }) {
    final updatedPermissions = state.permissions.map((page) {
      if (page.pageId != pageId) {
        return page;
      }

      final copy = page.copy();

      switch (permission) {
        case 'view':
          copy.canView = value;

          // View is the parent permission.
          if (!value) {
            copy.canCreate = false;
            copy.canUpdate = false;
            copy.canDelete = false;
          }
          break;

        case 'create':
          copy.canCreate = value;

          // Create requires View.
          if (value) {
            copy.canView = true;
          }
          break;

        case 'update':
          copy.canUpdate = value;

          // Update requires View.
          if (value) {
            copy.canView = true;
          }
          break;

        case 'delete':
          copy.canDelete = value;

          // Delete requires View.
          if (value) {
            copy.canView = true;
          }
          break;
      }

      return copy;
    }).toList();

    state = state.copyWith(permissions: updatedPermissions);
  }

  /// =============================================================
  /// SELECT ALL
  /// =============================================================

  void selectAll({required String permission, required bool value}) {
    final updatedPermissions = state.permissions.map((page) {
      final copy = page.copy();

      switch (permission) {
        case 'view':
          copy.canView = value;

          if (!value) {
            copy.canCreate = false;
            copy.canUpdate = false;
            copy.canDelete = false;
          }
          break;

        case 'create':
          copy.canCreate = value;

          if (value) {
            copy.canView = true;
          }
          break;

        case 'update':
          copy.canUpdate = value;

          if (value) {
            copy.canView = true;
          }
          break;

        case 'delete':
          copy.canDelete = value;

          if (value) {
            copy.canView = true;
          }
          break;
      }

      return copy;
    }).toList();

    state = state.copyWith(permissions: updatedPermissions);
  }

  /// =============================================================
  /// SAVE PERMISSIONS
  /// =============================================================

  Future<bool> savePermissions() async {
    if (state.selectedRoleId <= 0) {
      state = state.copyWith(errorMessage: 'Please select a role.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await api.saveRolePermissions(
        roleId: state.selectedRoleId,
        permissions: state.permissions,
      );

      state = state.copyWith(isSaving: false);

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: _cleanError(e));

      return false;
    }
  }

  /// =============================================================
  /// CREATE ROLE
  /// =============================================================

  Future<RoleModel?> createRole({
    required String name,
    required String value,
  }) async {
    state = state.copyWith(isCreatingRole: true, clearError: true);

    try {
      final role = await api.createRole(
        name: name,
        value: value,
        isActive: true,
      );

      final updatedRoles = [...state.roles, role];

      state = state.copyWith(
        roles: updatedRoles,
        selectedRoleId: role.id,
        isCreatingRole: false,
      );

      // Load permissions for newly created role.
      await _loadPermissionsForRole(role.id, showLoading: true);

      return role;
    } catch (e) {
      state = state.copyWith(
        isCreatingRole: false,
        errorMessage: _cleanError(e),
      );

      return null;
    }
  }

  /// =============================================================
  /// UPDATE ROLE
  /// =============================================================

  Future<RoleModel?> updateRole({
    required int id,
    required String name,
    required String value,
    required bool isActive,
  }) async {
    state = state.copyWith(isUpdatingRole: true, clearError: true);

    try {
      final updatedRole = await api.updateRole(
        id: id,
        name: name,
        value: value,
        isActive: isActive,
      );

      final updatedRoles = state.roles.map((role) {
        if (role.id == id) {
          return updatedRole;
        }

        return role;
      }).toList();

      state = state.copyWith(roles: updatedRoles, isUpdatingRole: false);

      return updatedRole;
    } catch (e) {
      state = state.copyWith(
        isUpdatingRole: false,
        errorMessage: _cleanError(e),
      );

      return null;
    }
  }

  /// =============================================================
  /// DELETE ROLE
  /// =============================================================

  Future<bool> deleteRole(int roleId) async {
    state = state.copyWith(isDeletingRole: true, clearError: true);

    try {
      await api.deleteRole(roleId);

      final updatedRoles = state.roles
          .where((role) => role.id != roleId)
          .toList();

      if (updatedRoles.isEmpty) {
        state = state.copyWith(
          roles: [],
          permissions: [],
          selectedRoleId: 0,
          isDeletingRole: false,
        );

        return true;
      }

      int nextRoleId = state.selectedRoleId;

      if (nextRoleId == roleId) {
        nextRoleId = updatedRoles.first.id;
      }

      state = state.copyWith(
        roles: updatedRoles,
        selectedRoleId: nextRoleId,
        isDeletingRole: false,
      );

      await _loadPermissionsForRole(nextRoleId, showLoading: true);

      return true;
    } catch (e) {
      state = state.copyWith(
        isDeletingRole: false,
        errorMessage: _cleanError(e),
      );

      return false;
    }
  }

  /// =============================================================
  /// ERROR CLEANER
  /// =============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}

/// ===============================================================
/// PROVIDER
/// ===============================================================

final roleManagementProvider =
    StateNotifierProvider<RoleManagementNotifier, RoleManagementState>((ref) {
      final api = ref.read(apiServiceProvider);

      return RoleManagementNotifier(api);
    });

/// ===============================================================
/// SCREEN
/// ===============================================================

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() =>
      _RoleManagementScreenState();
}

/// ===============================================================
/// SCREEN STATE
/// ===============================================================

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roleManagementProvider);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(child: _buildContent(context, state)),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: state.isCreatingRole
            ? null
            : () {
                _showAddRoleDialog(context);
              },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Role',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// =============================================================
  /// HEADER
  /// =============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 4),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role Management',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manage roles and page permissions',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(roleManagementProvider.notifier).loadRoles();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// CONTENT
  /// =============================================================

  Widget _buildContent(BuildContext context, RoleManagementState state) {
    if (state.isLoading && state.roles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null && state.roles.isEmpty) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.roles.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleDropdown(state),

          const SizedBox(height: 20),

          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                color: AppColors.primary,
                minHeight: 2,
              ),
            ),

          _buildPermissionCard(state),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// =============================================================
  /// ERROR STATE
  /// =============================================================

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.withValues(alpha: 0.8),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load roles',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                ref.read(roleManagementProvider.notifier).loadRoles();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =============================================================
  /// EMPTY STATE
  /// =============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 60,
            color: AppColors.textSecondary,
          ),

          const SizedBox(height: 16),

          const Text(
            'No active roles',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Create a role to configure page permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// ROLE DROPDOWN
  /// =============================================================

  Widget _buildRoleDropdown(RoleManagementState state) {
    final selectedRole = state.roles.where(
      (role) => role.id == state.selectedRoleId,
    );

    final selectedRoleId = selectedRole.isNotEmpty
        ? selectedRole.first.id
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Select Role',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (selectedRole.isNotEmpty) ...[
                IconButton(
                  tooltip: 'Edit Role',
                  onPressed: () {
                    _showEditRoleDialog(selectedRole.first);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),

                IconButton(
                  tooltip: 'Delete Role',
                  onPressed: () {
                    _confirmDeleteRole(selectedRole.first);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            initialValue: selectedRoleId,

            dropdownColor: AppColors.cardBackground,

            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),

              hintText: 'Select Role',

              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),

              filled: true,

              fillColor: AppColors.background,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.2,
                ),
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),

            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),

            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),

            items: state.roles.map((role) {
              return DropdownMenuItem<int>(
                value: role.id,
                child: Row(
                  children: [
                    // Icon(
                    //   _roleIcon(role.value),
                    //   size: 18,
                    //   color: AppColors.textSecondary,
                    // ),

                    const SizedBox(width: 10),

                    Text(
                      role.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            onChanged: (roleId) {
              if (roleId == null) {
                return;
              }

              ref.read(roleManagementProvider.notifier).selectRole(roleId);
            },
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// PERMISSION CARD
  /// =============================================================

  Widget _buildPermissionCard(RoleManagementState state) {
    final selectedRole = state.roles.where(
      (role) => role.id == state.selectedRoleId,
    );

    final roleName = selectedRole.isNotEmpty ? selectedRole.first.name : 'Role';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildPermissionHeader(roleName),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildSelectAllRow(state),
          ),

          const SizedBox(height: 12),

          _buildPermissionTable(state),

          const SizedBox(height: 16),

          _buildSaveButton(state),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// =============================================================
  /// PERMISSION HEADER
  /// =============================================================

  Widget _buildPermissionHeader(String roleName) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page Permissions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Configure access for selected role',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 6),

                  Flexible(
                    child: Text(
                      roleName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// SELECT ALL ROW
  /// =============================================================

  Widget _buildSelectAllRow(RoleManagementState state) {
    final permissions = state.permissions;

    final allView =
        permissions.isNotEmpty && permissions.every((p) => p.canView);

    final allCreate =
        permissions.isNotEmpty && permissions.every((p) => p.canCreate);

    final allUpdate =
        permissions.isNotEmpty && permissions.every((p) => p.canUpdate);

    final allDelete =
        permissions.isNotEmpty && permissions.every((p) => p.canDelete);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select All',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _buildPermissionHeaderCheckbox(
                label: 'View',
                value: allView,
                onChanged: (value) {
                  ref
                      .read(roleManagementProvider.notifier)
                      .selectAll(permission: 'view', value: value);
                },
              ),

              _buildPermissionHeaderCheckbox(
                label: 'Create',
                value: allCreate,
                onChanged: (value) {
                  ref
                      .read(roleManagementProvider.notifier)
                      .selectAll(permission: 'create', value: value);
                },
              ),

              _buildPermissionHeaderCheckbox(
                label: 'Update',
                value: allUpdate,
                onChanged: (value) {
                  ref
                      .read(roleManagementProvider.notifier)
                      .selectAll(permission: 'update', value: value);
                },
              ),

              _buildPermissionHeaderCheckbox(
                label: 'Delete',
                value: allDelete,
                onChanged: (value) {
                  ref
                      .read(roleManagementProvider.notifier)
                      .selectAll(permission: 'delete', value: value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// SELECT ALL CHECKBOX
  /// =============================================================

  Widget _buildPermissionHeaderCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Checkbox(
            value: value,
            onChanged: (v) {
              onChanged(v ?? false);
            },
            activeColor: AppColors.primary,
            checkColor: Colors.white,
            side: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),

          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// PERMISSION TABLE
  /// =============================================================

  Widget _buildPermissionTable(RoleManagementState state) {
    if (state.permissions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 42, color: AppColors.textSecondary),

            const SizedBox(height: 10),

            const Text(
              'No pages found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Please add active pages and configure permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildTableHeader(),

          const SizedBox(height: 10),

          ...state.permissions.map(
            (permission) => _buildPermissionRow(permission),
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// TABLE HEADER
  /// =============================================================

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Page',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          _buildColumnTitle('View'),
          _buildColumnTitle('Create'),
          _buildColumnTitle('Update'),
          _buildColumnTitle('Delete'),
        ],
      ),
    );
  }

  /// =============================================================
  /// COLUMN TITLE
  /// =============================================================

  Widget _buildColumnTitle(String title) {
    return SizedBox(
      width: 68,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// =============================================================
  /// PERMISSION ROW
  /// =============================================================

  Widget _buildPermissionRow(PagePermission permission) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  permission.icon,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.pageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      permission.pageKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildPermissionItem(
                  label: 'View',
                  value: permission.canView,
                  enabled: true,
                  onChanged: (value) {
                    ref
                        .read(roleManagementProvider.notifier)
                        .updatePermission(
                          pageId: permission.pageId,
                          permission: 'view',
                          value: value,
                        );
                  },
                ),
              ),

              Expanded(
                child: _buildPermissionItem(
                  label: 'Create',
                  value: permission.canCreate,
                  enabled: permission.canView,
                  onChanged: (value) {
                    ref
                        .read(roleManagementProvider.notifier)
                        .updatePermission(
                          pageId: permission.pageId,
                          permission: 'create',
                          value: value,
                        );
                  },
                ),
              ),

              Expanded(
                child: _buildPermissionItem(
                  label: 'Update',
                  value: permission.canUpdate,
                  enabled: permission.canView,
                  onChanged: (value) {
                    ref
                        .read(roleManagementProvider.notifier)
                        .updatePermission(
                          pageId: permission.pageId,
                          permission: 'update',
                          value: value,
                        );
                  },
                ),
              ),

              Expanded(
                child: _buildPermissionItem(
                  label: 'Delete',
                  value: permission.canDelete,
                  enabled: permission.canView,
                  onChanged: (value) {
                    ref
                        .read(roleManagementProvider.notifier)
                        .updatePermission(
                          pageId: permission.pageId,
                          permission: 'delete',
                          value: value,
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// =============================================================
  /// PERMISSION ITEM
  /// =============================================================

  Widget _buildPermissionItem({
    required String label,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled
          ? () {
              onChanged(!value);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: enabled
                  ? (newValue) {
                      onChanged(newValue ?? false);
                    }
                  : null,
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              side: BorderSide(
                color: AppColors.textSecondary.withValues(alpha: 0.55),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),

            const SizedBox(width: 2),

            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textSecondary.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =============================================================
  /// SAVE BUTTON
  /// =============================================================

  Widget _buildSaveButton(RoleManagementState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: state.isSaving || state.permissions.isEmpty
              ? null
              : () async {
                  final success = await ref
                      .read(roleManagementProvider.notifier)
                      .savePermissions();

                  if (!mounted) {
                    return;
                  }

                  final latestState = ref.read(roleManagementProvider);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Permissions saved successfully'
                            : latestState.errorMessage ??
                                  'Failed to save permissions',
                      ),
                      backgroundColor: success ? null : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 19),
          label: Text(
            state.isSaving ? 'Saving...' : 'Save Permissions',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// =============================================================
  /// ADD ROLE DIALOG
  /// =============================================================

  void _showAddRoleDialog(BuildContext context) {
    final nameController = TextEditingController();

    final valueController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Role',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: nameController,
                    label: 'Role Name',
                    hint: 'e.g. Asset Manager',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Role name is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  _buildDialogTextField(
                    controller: valueController,
                    label: 'Role Value',
                    hint: 'e.g. asset_manager',
                    icon: Icons.code,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Role value is required';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final name = nameController.text.trim();

                final value = valueController.text
                    .trim()
                    .toLowerCase()
                    .replaceAll(' ', '_');

                Navigator.pop(dialogContext);

                final role = await ref
                    .read(roleManagementProvider.notifier)
                    .createRole(name: name, value: value);

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      role != null
                          ? 'Role created successfully'
                          : ref.read(roleManagementProvider).errorMessage ??
                                'Failed to create role',
                    ),
                    backgroundColor: role != null ? null : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Role'),
            ),
          ],
        );
      },
    );
  }

  /// =============================================================
  /// EDIT ROLE DIALOG
  /// =============================================================

  void _showEditRoleDialog(RoleModel role) {
    final nameController = TextEditingController(text: role.name);

    final valueController = TextEditingController(text: role.value);

    bool isActive = role.isActive;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Role',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogTextField(
                        controller: nameController,
                        label: 'Role Name',
                        hint: 'Role name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Role name is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _buildDialogTextField(
                        controller: valueController,
                        label: 'Role Value',
                        hint: 'role_value',
                        icon: Icons.code,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Role value is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'Allow this role to be used',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        value: isActive,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final name = nameController.text.trim();

                    final value = valueController.text
                        .trim()
                        .toLowerCase()
                        .replaceAll(' ', '_');

                    Navigator.pop(dialogContext);

                    final updatedRole = await ref
                        .read(roleManagementProvider.notifier)
                        .updateRole(
                          id: role.id,
                          name: name,
                          value: value,
                          isActive: isActive,
                        );

                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          updatedRole != null
                              ? 'Role updated successfully'
                              : ref.read(roleManagementProvider).errorMessage ??
                                    'Failed to update role',
                        ),
                        backgroundColor: updatedRole != null
                            ? null
                            : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// =============================================================
  /// DELETE ROLE CONFIRMATION
  /// =============================================================

  void _confirmDeleteRole(RoleModel role) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Role?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${role.name}"?',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final success = await ref
                    .read(roleManagementProvider.notifier)
                    .deleteRole(role.id);

                if (!mounted) {
                  return;
                }

                final latestState = ref.read(roleManagementProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Role deleted successfully'
                          : latestState.errorMessage ?? 'Failed to delete role',
                    ),
                    backgroundColor: success ? null : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// =============================================================
  /// DIALOG TEXT FIELD
  /// =============================================================

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(icon, size: 19, color: AppColors.textSecondary),

        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),

        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),

        filled: true,

        fillColor: AppColors.background,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  /// =============================================================
  /// ROLE ICON
  /// =============================================================

  IconData _roleIcon(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return Icons.admin_panel_settings_outlined;

      case 'cafm_manager':
      case 'cafmmanager':
        return Icons.manage_accounts_outlined;

      case 'supervisor':
        return Icons.supervisor_account_outlined;

      case 'facilities_executive':
      case 'facilitiesexecutive':
        return Icons.apartment_outlined;

      case 'technician':
        return Icons.build_outlined;

      default:
        return Icons.person_outline;
    }
  }
}
