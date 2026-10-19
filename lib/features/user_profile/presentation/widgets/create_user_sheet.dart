import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../../../../core/utils/api_service.dart';
import '../../../../core/utils/role_model.dart';

enum _LoginAccess { create, none }

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // USER DETAILS
  // ============================================================

  final _fullNameCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  // ============================================================
  // LOGIN DETAILS
  // ============================================================

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ============================================================
  // DROPDOWNS
  // ============================================================

  String? _department;
  String? _designation;
  String? _employeeType;

  // Dynamic Role
  RoleModel? _role;

  // ============================================================
  // COUNTRY
  // ============================================================

  String _countryName = 'United Arab Emirates';
  String _countryCode = '+971';

  // ============================================================
  // DOB
  // ============================================================

  DateTime? _dateOfBirth;

  // ============================================================
  // LOGIN ACCESS
  // ============================================================

  _LoginAccess _access = _LoginAccess.create;

  bool _sendCredentials = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ============================================================
  // STATE
  // ============================================================

  bool _saving = false;
  bool _created = false;

  String _createdUserId = '';

  // ============================================================
  // DYNAMIC ROLES
  // ============================================================

  List<RoleModel> _roles = [];
  bool _loadingRoles = true;

  // ============================================================
  // CAFM DEPARTMENTS
  // ============================================================

  final List<String> _departments = [
    'Facility Management',
    'Operations',
    'Maintenance',
    'Asset Management',
    'Space Management',
    'HSE',
    'Procurement',
    'Finance & Administration',
    'HR',
    'IT',
  ];

  final List<String> _designations = [
    'Manager',
    'Supervisor',
    'Technician',
    'Coordinator',
    'Officer',
  ];

  final List<String> _employeeTypes = ['Full-time', 'Part-time', 'Contract'];

  // ============================================================
  // COUNTRIES
  // ============================================================

  final List<Map<String, String>> _countries = [
    {'name': 'United Arab Emirates', 'code': '+971'},
    {'name': 'India', 'code': '+91'},
    {'name': 'Saudi Arabia', 'code': '+966'},
    {'name': 'Qatar', 'code': '+974'},
    {'name': 'Oman', 'code': '+968'},
    {'name': 'Kuwait', 'code': '+965'},
    {'name': 'Bahrain', 'code': '+973'},
    {'name': 'United States', 'code': '+1'},
    {'name': 'United Kingdom', 'code': '+44'},
    {'name': 'Canada', 'code': '+1'},
    {'name': 'Australia', 'code': '+61'},
    {'name': 'New Zealand', 'code': '+64'},
    {'name': 'Singapore', 'code': '+65'},
    {'name': 'Malaysia', 'code': '+60'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'Bangladesh', 'code': '+880'},
    {'name': 'Sri Lanka', 'code': '+94'},
    {'name': 'Nepal', 'code': '+977'},
    {'name': 'Philippines', 'code': '+63'},
    {'name': 'Indonesia', 'code': '+62'},
    {'name': 'China', 'code': '+86'},
    {'name': 'Japan', 'code': '+81'},
    {'name': 'South Korea', 'code': '+82'},
    {'name': 'Germany', 'code': '+49'},
    {'name': 'France', 'code': '+33'},
    {'name': 'Italy', 'code': '+39'},
    {'name': 'Spain', 'code': '+34'},
    {'name': 'Netherlands', 'code': '+31'},
    {'name': 'Switzerland', 'code': '+41'},
    {'name': 'South Africa', 'code': '+27'},
    {'name': 'Egypt', 'code': '+20'},
    {'name': 'Jordan', 'code': '+962'},
    {'name': 'Turkey', 'code': '+90'},
  ];

  // ============================================================
  // INIT STATE
  // ============================================================
  late final ApiService api;
  @override
  void initState() {
    super.initState();

    api = ref.read(apiServiceProvider);

    _loadRoles();
  }

  // ============================================================
  // LOAD ROLES DYNAMICALLY
  // ============================================================

  Future<void> _loadRoles() async {
    if (mounted) {
      setState(() {
        _loadingRoles = true;
      });
    }

    debugPrint('========================================');
    debugPrint('LOAD ROLES START');
    debugPrint('========================================');

    try {
      debugPrint('Calling api.getRoles()...');

      final roles = await api.getRoles();

      debugPrint('api.getRoles() completed');
      debugPrint('Total roles received: ${roles.length}');

      for (final role in roles) {
        debugPrint(
          'ROLE => id=${role.id}, '
          'name=${role.name}, '
          'value=${role.value}, '
          'active=${role.isActive}',
        );
      }

      if (!mounted) return;

      final activeRoles = roles.where((role) => role.isActive).toList();

      debugPrint('Active roles: ${activeRoles.length}');

      setState(() {
        _roles = activeRoles;

        if (_roles.isNotEmpty) {
          _role = _roles.first;
        } else {
          _role = null;
        }

        _loadingRoles = false;
      });

      debugPrint('========================================');
      debugPrint('LOAD ROLES SUCCESS');
      debugPrint('Loading = $_loadingRoles');
      debugPrint('Roles = ${_roles.length}');
      debugPrint('Selected Role = ${_role?.name}');
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('LOAD ROLES FAILED');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        _loadingRoles = false;
        _roles = [];
        _role = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load roles: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _employeeIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _locationCtrl.dispose();

    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final email = value.trim();

    final regex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+\-/=?^_`{|}~]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
    );

    if (!regex.hasMatch(email) || email.contains('..')) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _dobValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date of birth is required';
    }

    if (_dateOfBirth == null) {
      return 'Select a valid date of birth';
    }

    if (!_dateOfBirth!.isBefore(DateTime.now())) {
      return 'Date of birth must be in the past';
    }

    return null;
  }

  String? _usernameValidator(String? value) {
    if (_access == _LoginAccess.none) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    if (value.trim().length < 3) {
      return 'Username must contain at least 3 characters';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (_access == _LoginAccess.none) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Minimum 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include an uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include a lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include a number';
    }

    if (!RegExp(r'[!@#\$&*~%^()\-_=+]').hasMatch(value)) {
      return 'Include a special character';
    }

    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (_access == _LoginAccess.none) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != _passwordCtrl.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ============================================================
  // PASSWORD GENERATOR
  // ============================================================

  void _generatePassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnpqrstuvwxyz';
    const numbers = '23456789';
    const symbols = '!@#\$&*';

    final random = Random();

    String pick(String chars) {
      return chars[random.nextInt(chars.length)];
    }

    final password = [
      pick(upper),
      pick(lower),
      pick(numbers),
      pick(symbols),
      for (int i = 0; i < 6; i++) pick(upper + lower + numbers),
    ]..shuffle(random);

    final generatedPassword = password.join();

    setState(() {
      _passwordCtrl.text = generatedPassword;
      _confirmPasswordCtrl.text = generatedPassword;
      _obscurePassword = false;
      _obscureConfirmPassword = false;
    });
  }

  // ============================================================
  // COUNTRY SELECTOR
  // ============================================================

  Future<void> _selectCountry() async {
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: const Color(0xFF182129),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        String search = '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _countries.where((country) {
              final query = search.trim().toLowerCase();

              if (query.isEmpty) {
                return true;
              }

              return country['name']!.toLowerCase().contains(query) ||
                  country['code']!.contains(query);
            }).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Country',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() {
                            search = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search country or code',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF202A32),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) {
                          return const Divider(
                            color: Colors.white10,
                            height: 1,
                          );
                        },
                        itemBuilder: (context, index) {
                          final country = filtered[index];

                          final selected =
                              country['code'] == _countryCode &&
                              country['name'] == _countryName;

                          return ListTile(
                            onTap: () {
                              Navigator.pop(context, country);
                            },
                            title: Text(
                              country['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Text(
                              country['code']!,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            selected: selected,
                            selectedTileColor: AppColors.primaryBlue
                                .withOpacity(0.08),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _countryName = selected['name']!;
      _countryCode = selected['code']!;
    });
  }

  // ============================================================
  // PHONE FIELD
  // ============================================================

  Widget _phoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Phone'),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _saving ? null : _selectCountry,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF202A32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 115),
                      child: Text(
                        _countryName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      _countryCode,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                cursorColor: AppColors.primaryBlue,
                decoration: _inputDecoration(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final initialDate =
        _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now)
          ? DateTime(now.year - 18, now.month, now.day)
          : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'SELECT DATE OF BIRTH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: Color(0xFF202A32),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _dateOfBirth = picked;

      _dobCtrl.text =
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  // ============================================================
  // CREATE USER
  // ============================================================

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      //final api = ref.read(apiServiceProvider);

      final data = {
        'full_name': _fullNameCtrl.text.trim(),
        'employee_id': _employeeIdCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'country_code': _countryCode,
        'department': _department,
        'designation': _designation,
        'employee_type': _employeeType,

        'date_of_birth': _dateOfBirth != null
            ? '${_dateOfBirth!.year.toString().padLeft(4, '0')}-'
                  '${_dateOfBirth!.month.toString().padLeft(2, '0')}-'
                  '${_dateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,

        'location': _locationCtrl.text.trim(),

        // ======================================================
        // DYNAMIC ROLE
        // ======================================================
        'role': _role!.value,

        // ======================================================
        // LOGIN ACCESS
        // ======================================================
        'login_access': _access == _LoginAccess.create ? 1 : 0,

        'username': _access == _LoginAccess.create
            ? _usernameCtrl.text.trim()
            : null,

        'password': _access == _LoginAccess.create ? _passwordCtrl.text : null,

        'send_credentials': _access == _LoginAccess.create && _sendCredentials
            ? 1
            : 0,
      };

      debugPrint('Create User Request: $data');

      final response = await api.createUser(data);

      if (!mounted) {
        return;
      }

      final responseData = response.data;

      debugPrint('Create User Response: $responseData');

      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid response received from server.');
      }

      final success = responseData['success'] == true;

      if (!success) {
        throw Exception(
          responseData['message']?.toString() ?? 'Unable to create user.',
        );
      }

      // ========================================================
      // CREATED USER
      // ========================================================

      final userData = responseData['user'];

      String createdId = '-';

      if (userData is Map<String, dynamic>) {
        createdId = userData['id']?.toString() ?? '-';
      }

      setState(() {
        _saving = false;
        _created = true;
        _createdUserId = createdId;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      String message = e.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,

      fillColor: const Color(0xFF202A32),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),

      suffixIcon: suffixIcon,

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
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          children: required
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,

          style: const TextStyle(color: Colors.white, fontSize: 13),

          cursorColor: AppColors.primaryBlue,

          decoration: _inputDecoration(suffixIcon: suffixIcon),
        ),
      ],
    );
  }

  // ============================================================
  // GENERIC DROPDOWN
  // ============================================================

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    bool required = false,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),

        DropdownButtonFormField<T>(
          initialValue: value,

          dropdownColor: const Color(0xFF202A32),

          style: const TextStyle(color: Colors.white, fontSize: 13),

          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),

          decoration: _inputDecoration(),

          hint: Text(
            'Select $label',
            style: const TextStyle(color: Colors.white38, fontSize: 12.5),
          ),

          validator: validator,

          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),

          onChanged: _saving ? null : onChanged,
        ),
      ],
    );
  }

  // ============================================================
  // DYNAMIC ROLE DROPDOWN
  // ============================================================

  Widget _roleDropdown() {
    if (_loadingRoles) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Role', required: true),

          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF202A32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading roles...',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_roles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Role', required: true),

          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF202A32),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No active roles available',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _dropdown<RoleModel>(
      label: 'Role',
      value: _role,
      items: _roles,

      // Dynamic role name from database
      itemLabel: (role) => role.name,

      required: true,

      validator: (value) {
        if (value == null) {
          return 'Role is required';
        }

        return null;
      },

      onChanged: (value) {
        setState(() {
          _role = value;
        });
      },
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN ACCESS SELECTOR
  // ============================================================

  Widget _loginAccessSelector() {
    Widget option({
      required _LoginAccess value,
      required String title,
      required String description,
      required IconData icon,
    }) {
      final selected = _access == value;

      return Expanded(
        child: GestureDetector(
          onTap: _saving
              ? null
              : () {
                  setState(() {
                    _access = value;
                  });
                },

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),

            padding: const EdgeInsets.all(11),

            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryBlue.withOpacity(0.12)
                  : const Color(0xFF202A32),

              borderRadius: BorderRadius.circular(11),

              border: Border.all(
                color: selected ? AppColors.primaryBlue : Colors.white12,
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 19,
                      color: selected ? AppColors.primaryBlue : Colors.white54,
                    ),

                    const Spacer(),

                    Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBlue
                              : Colors.white30,
                        ),
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        option(
          value: _LoginAccess.create,
          title: 'Create Login',
          description: 'User can sign in to the application.',
          icon: Icons.lock_open_rounded,
        ),

        const SizedBox(width: 10),

        option(
          value: _LoginAccess.none,
          title: 'No Login',
          description: 'Create user without application access.',
          icon: Icons.block_rounded,
        ),
      ],
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildForm() {
    return Scaffold(
      backgroundColor: const Color(0xFF141D24),

      appBar: AppBar(
        backgroundColor: const Color(0xFF141D24),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
        ),

        title: const Text(
          'Create New User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      // ==================================================
                      // BASIC INFORMATION
                      // ==================================================
                      _sectionTitle('BASIC INFORMATION'),

                      _textField(
                        label: 'Full Name',
                        controller: _fullNameCtrl,
                        required: true,
                        validator: (value) =>
                            _requiredValidator(value, 'Full name'),
                      ),

                      const SizedBox(height: 12),

                      _textField(
                        label: 'Employee ID',
                        controller: _employeeIdCtrl,
                        required: true,
                        validator: (value) =>
                            _requiredValidator(value, 'Employee ID'),
                      ),

                      const SizedBox(height: 12),

                      _textField(
                        label: 'Email',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),

                      const SizedBox(height: 12),

                      _phoneField(),

                      const SizedBox(height: 12),

                      _dropdown<String>(
                        label: 'Department',
                        value: _department,
                        items: _departments,
                        itemLabel: (value) => value,
                        required: true,
                        validator: (value) =>
                            _requiredValidator(value, 'Department'),
                        onChanged: (value) {
                          setState(() {
                            _department = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      _dropdown<String>(
                        label: 'Designation',
                        value: _designation,
                        items: _designations,
                        itemLabel: (value) => value,
                        onChanged: (value) {
                          setState(() {
                            _designation = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      _dropdown<String>(
                        label: 'Employee Type',
                        value: _employeeType,
                        items: _employeeTypes,
                        itemLabel: (value) => value,
                        onChanged: (value) {
                          setState(() {
                            _employeeType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // DOB
                      // ==================================================
                      _textField(
                        label: 'Date of Birth',
                        controller: _dobCtrl,
                        required: true,
                        validator: _dobValidator,
                        suffixIcon: IconButton(
                          tooltip: 'Select date',
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white54,
                            size: 19,
                          ),
                          onPressed: _saving ? null : _selectDateOfBirth,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // LOCATION
                      // ==================================================
                      _textField(
                        label: 'Location',
                        controller: _locationCtrl,
                        suffixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white54,
                          size: 19,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // DYNAMIC ROLE
                      // ==================================================
                      _roleDropdown(),

                      const SizedBox(height: 18),

                      const Divider(color: Colors.white10),

                      const SizedBox(height: 14),

                      // ==================================================
                      // APPLICATION ACCESS
                      // ==================================================
                      _sectionTitle('APPLICATION ACCESS'),

                      _label('Login Access'),

                      _loginAccessSelector(),

                      // ==================================================
                      // CREATE LOGIN
                      // ==================================================
                      if (_access == _LoginAccess.create) ...[
                        const SizedBox(height: 14),
                        _buildLoginDetails(),
                      ],

                      // ==================================================
                      // NO LOGIN
                      // ==================================================
                      if (_access == _LoginAccess.none) ...[
                        const SizedBox(height: 14),
                        _buildNoLoginMessage(),
                      ],

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // BOTTOM BUTTONS
              // ==================================================
              Container(
                padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),

                decoration: const BoxDecoration(
                  color: Color(0xFF182129),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),

                child: SafeArea(
                  top: false,

                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },

                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),

                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _createUser,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),

                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create User',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN DETAILS
  // ============================================================

  Widget _buildLoginDetails() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFF1A242C),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white10),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'LOGIN CREDENTIALS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 14),

          _textField(
            label: 'Username',
            controller: _usernameCtrl,
            required: true,
            validator: _usernameValidator,
          ),

          const SizedBox(height: 12),

          _textField(
            label: 'Password',
            controller: _passwordCtrl,
            required: true,
            obscureText: _obscurePassword,
            validator: _passwordValidator,

            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Generate password',
                  icon: const Icon(
                    Icons.autorenew_rounded,
                    size: 18,
                    color: Colors.white54,
                  ),
                  onPressed: _saving ? null : _generatePassword,
                ),

                IconButton(
                  tooltip: 'Show password',
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Minimum 8 characters with uppercase, lowercase, number and symbol.',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),

          const SizedBox(height: 12),

          _textField(
            label: 'Confirm Password',
            controller: _confirmPasswordCtrl,
            required: true,
            obscureText: _obscureConfirmPassword,
            validator: _confirmPasswordValidator,

            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: 18,
                color: Colors.white54,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,

            value: _sendCredentials,

            activeThumbColor: AppColors.primaryBlue,

            onChanged: _saving
                ? null
                : (value) {
                    setState(() {
                      _sendCredentials = value;
                    });
                  },

            title: const Text(
              'Send login credentials to user',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            subtitle: const Text(
              'Send credentials to the registered email.',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO LOGIN MESSAGE
  // ============================================================

  Widget _buildNoLoginMessage() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFF202A32),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white10),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 32,
            height: 32,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.info_outline_rounded,
              size: 17,
              color: Colors.white54,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'No Login Access',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'This user will be created without application login access.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS SCREEN
  // ============================================================

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF141D24),

      appBar: AppBar(
        backgroundColor: const Color(0xFF141D24),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: const Text(
          'User Created',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,

                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 42,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'User Created Successfully',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  '${_fullNameCtrl.text.trim()} has been added successfully.',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xFF202A32),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),

                  child: Column(
                    children: [
                      _summaryRow('User ID', _createdUserId),

                      const Divider(color: Colors.white10, height: 20),

                      _summaryRow('Name', _fullNameCtrl.text.trim()),

                      const Divider(color: Colors.white10, height: 20),

                      _summaryRow('Employee ID', _employeeIdCtrl.text.trim()),

                      const Divider(color: Colors.white10, height: 20),

                      _summaryRow('Department', _department ?? '-'),

                      const Divider(color: Colors.white10, height: 20),

                      // Dynamic Role Name
                      _summaryRow('Role', _role?.name ?? '-'),

                      const Divider(color: Colors.white10, height: 20),

                      _summaryRow(
                        'Login Access',
                        _access == _LoginAccess.create ? 'Enabled' : 'Disabled',
                      ),

                      if (_access == _LoginAccess.create) ...[
                        const Divider(color: Colors.white10, height: 20),

                        _summaryRow('Username', _usernameCtrl.text.trim()),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_created) {
      return _buildSuccessScreen();
    }

    return _buildForm();
  }
}
