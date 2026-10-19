import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assets_app/core/utils/api_service.dart';
import '../theme/app_colors.dart';
import '../../../../core/utils/role_model.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const EditUserScreen({super.key, required this.user});

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _departmentController;
  late final TextEditingController _designationController;
  late final TextEditingController _employeeTypeController;
  late final TextEditingController _locationController;

  String _selectedRole = '';
  String _selectedStatus = '';

  bool _saving = false;
  //List<Map<String, dynamic>> _roles = [];
  bool _loadingRoles = true;

  List<RoleModel> _roles = [];

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(
      text: widget.user['full_name']?.toString() ?? '',
    );

    _employeeIdController = TextEditingController(
      text: widget.user['employee_id']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: widget.user['email']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.user['phone']?.toString() ?? '',
    );

    _departmentController = TextEditingController(
      text: widget.user['department']?.toString() ?? '',
    );

    _designationController = TextEditingController(
      text: widget.user['designation']?.toString() ?? '',
    );

    _employeeTypeController = TextEditingController(
      text: widget.user['employee_type']?.toString() ?? '',
    );

    _locationController = TextEditingController(
      text: widget.user['location']?.toString() ?? '',
    );

    _selectedRole = widget.user['role']?.toString() ?? '';
    _selectedStatus = widget.user['status']?.toString() ?? 'active';

    _loadRoles();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _employeeTypeController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = widget.user['id'];

    if (userId == null) {
      _showMessage('User ID is missing.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final api = ref.read(apiServiceProvider);

      final response = await api.updateUser(
        id: userId.toString(),
        fullName: _fullNameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _departmentController.text.trim(),
        designation: _designationController.text.trim(),
        employeeType: _employeeTypeController.text.trim(),
        location: _locationController.text.trim(),
        role: _selectedRole,
        status: _selectedStatus,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Unable to update user.',
        );
      }

      if (!mounted) return;

      _showMessage(data['message']?.toString() ?? 'User updated successfully.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _loadRoles() async {
    try {
      final api = ref.read(apiServiceProvider);

      final roles = await api.getRoles();

      if (!mounted) return;

      setState(() {
        _roles = roles;
        _loadingRoles = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingRoles = false;
      });

      _showMessage(
        'Failed to load roles: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              'Edit User',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Update user information',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _buildSectionTitle('Basic Information', Icons.person_outline),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  required: true,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _employeeIdController,
                  label: 'Employee ID',
                  icon: Icons.badge_outlined,
                  required: true,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),

                _buildSectionTitle(
                  'Employment Information',
                  Icons.work_outline,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _departmentController,
                  label: 'Department',
                  icon: Icons.apartment_outlined,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _designationController,
                  label: 'Designation',
                  icon: Icons.work_outline,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _employeeTypeController,
                  label: 'Employee Type',
                  icon: Icons.badge_outlined,
                ),

                const SizedBox(height: 12),

                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 24),

                _buildSectionTitle(
                  'Access & Status',
                  Icons.admin_panel_settings_outlined,
                ),

                const SizedBox(height: 12),

                _buildRoleDropdown(),

                const SizedBox(height: 12),

                _buildStatusDropdown(),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _updateUser,

                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),

                    label: Text(
                      _saving ? 'Updating...' : 'Update User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(icon),

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

      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  // ============================================================
  // ROLE DROPDOWN
  // ============================================================

  // ============================================================
  // ROLE DROPDOWN
  // ============================================================

  Widget _buildRoleDropdown() {
    final validSelectedRole = _roles.any((role) => role.value == _selectedRole);

    return DropdownButtonFormField<String>(
      value: validSelectedRole ? _selectedRole : null,
      isExpanded: true,

      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
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

      hint: _loadingRoles
          ? const Text('Loading roles...')
          : const Text('Select Role'),

      items: _roles.where((role) => role.isActive).map((role) {
        return DropdownMenuItem<String>(
          value: role.value,
          child: Text(role.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),

      onChanged: _loadingRoles
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                _selectedRole = value;
              });
            },

      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Role is required';
        }

        return null;
      },
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

        prefixIcon: const Icon(Icons.circle_outlined, size: 20),

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

      items: const [
        DropdownMenuItem(value: 'active', child: Text('Active')),

        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
      ],

      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }
}
