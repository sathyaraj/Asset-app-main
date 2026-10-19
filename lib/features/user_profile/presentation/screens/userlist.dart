import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assets_app/core/utils/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/create_user_sheet.dart';
import 'edit_user_screen.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _users = [];

  bool _loading = true;

  String? _error;

  String _selectedRole = '';

  String _selectedStatus = '';

  int _currentPage = 1;

  final int _limit = 10;

  int _totalUsers = 0;

  int _totalPages = 0;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);

      final response = await api.getUsers(
        search: _searchController.text.trim(),
        role: _selectedRole,
        status: _selectedStatus,
        page: _currentPage,
        limit: _limit,
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Unable to load users.');
      }

      final data = responseData['data'] as Map<String, dynamic>? ?? {};

      final userList = data['users'] as List<dynamic>? ?? [];

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        _users = userList;

        _totalUsers = pagination['total'] ?? 0;

        _totalPages = pagination['total_pages'] ?? 0;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;

        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _search() {
    _currentPage = 1;
    _loadUsers();
  }

  // ============================================================
  // ROLE FILTER
  // ============================================================

  void _changeRole(String? value) {
    setState(() {
      _selectedRole = value ?? '';
      _currentPage = 1;
    });

    _loadUsers();
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  void _changeStatus(String? value) {
    setState(() {
      _selectedStatus = value ?? '';
      _currentPage = 1;
    });

    _loadUsers();
  }

  // ============================================================
  // CLEAR FILTERS
  // ============================================================

  void _clearFilters() {
    setState(() {
      _searchController.clear();

      _selectedRole = '';

      _selectedStatus = '';

      _currentPage = 1;
    });

    _loadUsers();
  }

  // ============================================================
  // NEXT PAGE
  // ============================================================

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });

      _loadUsers();
    }
  }

  // ============================================================
  // PREVIOUS PAGE
  // ============================================================

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });

      _loadUsers();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Manage employees and users',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(),

            Expanded(child: _buildBody()),

            if (!_loading && _error == null && _totalPages > 1)
              _buildPagination(),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateUserScreen()),
          );

          // Create User page-ல் user successfully created
          // என்றால் User List-ஐ refresh செய்யும்
          if (result == true && mounted) {
            _loadUsers();
          }
        },

        icon: const Icon(Icons.person_add_alt_1_rounded),

        label: const Text(
          'Add User',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // TOP SECTION
  // ============================================================

  Widget _buildTopSection() {
    return Container(
      color: AppColors.background,

      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),

      child: Column(
        children: [
          // ----------------------------------------------------
          // SUMMARY
          // ----------------------------------------------------
          Row(
            children: [
              _buildSummaryCard(
                icon: Icons.people_alt_outlined,
                title: 'Total Users',
                value: '$_totalUsers',
              ),

              const SizedBox(width: 12),

              _buildSummaryCard(
                icon: Icons.verified_user_outlined,
                title: 'Active',
                value: _activeCount.toString(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------
          // SEARCH
          // ----------------------------------------------------
          TextField(
            controller: _searchController,

            onSubmitted: (_) {
              _search();
            },

            decoration: InputDecoration(
              hintText: 'Search name, employee ID, email...',

              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),

              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),

              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _search();
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : IconButton(
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),

              filled: true,

              fillColor: AppColors.storedGrey,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ----------------------------------------------------
          // FILTERS
          // ----------------------------------------------------
          Row(
            children: [
              Expanded(child: _buildRoleDropdown()),

              const SizedBox(width: 8),

              Expanded(child: _buildStatusDropdown()),

              const SizedBox(width: 4),

              SizedBox(
                width: 36,
                height: 48,
                child: IconButton(
                  padding: EdgeInsets.zero,

                  tooltip: 'Clear filters',

                  onPressed:
                      (_selectedRole.isNotEmpty ||
                          _selectedStatus.isNotEmpty ||
                          _searchController.text.isNotEmpty)
                      ? _clearFilters
                      : null,

                  icon: const Icon(
                    Icons.filter_alt_off_outlined,
                    color: AppColors.iconChipBg,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: AppColors.storedGrey,

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: AppColors.cardBackground),
        ),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,

              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),

                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ROLE DROPDOWN
  // ============================================================

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole.isEmpty ? null : _selectedRole,

      isExpanded: true,

      decoration: InputDecoration(
        labelText: 'Role',

        prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 18),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 38,
          maxWidth: 38,
          minHeight: 40,
          maxHeight: 40,
        ),

        filled: true,

        fillColor: AppColors.storedGrey,

        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),

        // No border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      items: const [
        DropdownMenuItem<String>(
          value: 'admin',
          child: Text('Admin', overflow: TextOverflow.ellipsis),
        ),

        DropdownMenuItem<String>(
          value: 'employee',
          child: Text('Employee', overflow: TextOverflow.ellipsis),
        ),
      ],

      onChanged: _changeRole,
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus.isEmpty ? null : _selectedStatus,

      isExpanded: true,

      decoration: InputDecoration(
        labelText: 'Status',

        prefixIcon: const Icon(Icons.circle_outlined, size: 18),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 38,
          maxWidth: 38,
          minHeight: 40,
          maxHeight: 40,
        ),

        filled: true,

        fillColor: AppColors.storedGrey,

        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),

        // No border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      items: const [
        DropdownMenuItem<String>(
          value: 'active',
          child: Text('Active', overflow: TextOverflow.ellipsis),
        ),

        DropdownMenuItem<String>(
          value: 'inactive',
          child: Text('Inactive', overflow: TextOverflow.ellipsis),
        ),
      ],

      onChanged: _changeStatus,
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_users.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,

      child: ListView.builder(
        padding: const EdgeInsets.all(16),

        physics: const AlwaysScrollableScrollPhysics(),

        itemCount: _users.length,

        itemBuilder: (context, index) {
          final user = _users[index] as Map<String, dynamic>;

          return _buildUserCard(user);
        },
      ),
    );
  }

  // ============================================================
  // USER CARD
  // ============================================================

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['full_name']?.toString() ?? 'Unknown User';

    final employeeId = user['employee_id']?.toString() ?? '-';

    final email = user['email']?.toString() ?? '-';

    final department = user['department']?.toString() ?? '-';

    final designation = user['designation']?.toString() ?? '-';

    final role = user['role']?.toString() ?? '-';

    final status = user['status']?.toString() ?? 'inactive';

    final isActive = status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: AppColors.storedGrey),

        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: () {
          _showUserDetails(user);
        },

        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // AVATAR
              // ------------------------------------------------
              _buildAvatar(name),

              const SizedBox(width: 13),

              // ------------------------------------------------
              // USER DETAILS
              // ------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        _buildStatusBadge(isActive),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Employee ID: $employeeId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.work_outline_rounded,
                          size: 15,
                          color: Color(0xFF9CA3AF),
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            designation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.apartment_outlined,
                          size: 15,
                          color: Color(0xFF9CA3AF),
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            department,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 15,
                          color: Color(0xFF9CA3AF),
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    _buildRoleBadge(role),
                  ],
                ),
              ),

              // ------------------------------------------------
              // MENU
              // ------------------------------------------------
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,

                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),

                onSelected: (value) {
                  if (value == 'view') {
                    _showUserDetails(user);
                  }

                  if (value == 'edit') {
                    _editUser(user);
                  }

                  if (value == 'delete') {
                    _deleteUser(user);
                  }
                },

                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('View'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 50,
      height: 50,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),

        color: const Color(0xFFEFF6FF),
      ),

      alignment: Alignment.center,

      child: Text(
        initial,

        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: 6,
            height: 6,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: active ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),

          const SizedBox(width: 5),

          Text(
            active ? 'Active' : 'Inactive',

            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,

              color: active ? const Color(0xFF047857) : const Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE BADGE
  // ============================================================

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        role.toUpperCase(),

        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Color(0xFF9CA3AF),
            ),

            const SizedBox(height: 14),

            const Text(
              'Unable to load users',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 7),

            Text(
              _error ?? 'Please try again.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _loadUsers,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: 80,
            height: 80,

            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),

              borderRadius: BorderRadius.circular(25),
            ),

            child: const Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'No users found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          const Text(
            'Try changing your search or filters.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      decoration: const BoxDecoration(
        color: AppColors.cardBackground,

        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          IconButton(
            onPressed: _currentPage > 1 ? _previousPage : null,

            icon: const Icon(Icons.chevron_left_rounded),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),

              borderRadius: BorderRadius.circular(8),
            ),

            child: Text(
              '$_currentPage / $_totalPages',

              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          IconButton(
            onPressed: _currentPage < _totalPages ? _nextPage : null,

            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE COUNT
  // ============================================================

  int get _activeCount {
    return _users.where((user) {
      final status = user['status']?.toString() ?? '';

      return status.toLowerCase() == 'active';
    }).length;
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: AppColors.background,

      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),

          decoration: const BoxDecoration(
            color: AppColors.storedGrey,

            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),

          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,

                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  user['full_name'] ?? 'User Details',

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 20),

                _detailRow('Employee ID', user['employee_id']),

                _detailRow('Email', user['email']),

                _detailRow('Phone', user['phone']),

                _detailRow('Department', user['department']),

                _detailRow('Designation', user['designation']),

                _detailRow('Employee Type', user['employee_type']),

                _detailRow('Location', user['location']),

                _detailRow('Role', user['role']),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      _editUser(user);
                    },

                    child: const Text('Edit User'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 110,

            child: Text(
              label,

              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value?.toString() ?? '-',

              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT USER
  // ============================================================

  void _editUser(Map<String, dynamic> user) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditUserScreen(
        user: user,
      ),
    ),
  ).then((result) {
    if (result == true && mounted) {
      _loadUsers();
    }
  });
}

  // ============================================================
  // DELETE USER
  // ============================================================

  void _deleteUser(Map<String, dynamic> user) {
    // Connect Delete User API here
  }
}
