import 'package:flutter/material.dart';
import 'package:assets_app/core/utils/role_model.dart';

//import '../models/cafm_role.dart';
//import '../models/role_model.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../../../../core/utils/api_service.dart';

// =========================================================
// COUNTRY DATA — dial code + flag, for the phone field.
// This is a curated common-country list, not the full ISO
// set. Tell me if you need specific countries added.
// =========================================================

class _Country {
  final String name;
  final String dialCode;
  final String flag;

  const _Country({
    required this.name,
    required this.dialCode,
    required this.flag,
  });
}

const List<_Country> _countries = [
  _Country(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
  _Country(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  _Country(name: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
  _Country(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  _Country(name: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
  _Country(name: 'Oman', dialCode: '+968', flag: '🇴🇲'),
  _Country(name: 'India', dialCode: '+91', flag: '🇮🇳'),
  _Country(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  _Country(name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  _Country(name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  _Country(name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
  _Country(name: 'Nepal', dialCode: '+977', flag: '🇳🇵'),
  _Country(name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  _Country(name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  _Country(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  _Country(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  _Country(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  _Country(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  _Country(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  _Country(name: 'France', dialCode: '+33', flag: '🇫🇷'),
  _Country(name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  _Country(name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  _Country(name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  _Country(name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  _Country(name: 'China', dialCode: '+86', flag: '🇨🇳'),
  _Country(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  _Country(name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  _Country(name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  _Country(name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  _Country(name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  _Country(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  _Country(name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  _Country(name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  _Country(name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
  _Country(name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
];

class EditProfileSheet extends StatefulWidget {
  final UserProfile profile;

  const EditProfileSheet({super.key, required this.profile});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _locationCtrl;

  late RoleModel _role;
  late _Country _selectedCountry;

  List<RoleModel> _roles = [];
  bool _loadingRoles = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final rawPhone = widget.profile.phoneNumber.trim();

    _Country matched = _countries.first;
    String remainder = rawPhone;

    for (final country in _countries) {
      if (rawPhone.startsWith(country.dialCode)) {
        matched = country;
        remainder = rawPhone.substring(country.dialCode.length).trim();
        break;
      }
    }

    _selectedCountry = matched;

    _phoneCtrl = TextEditingController(text: remainder);
    _emailCtrl = TextEditingController(text: widget.profile.email);
    _locationCtrl = TextEditingController(text: widget.profile.location);

    _role = widget.profile.role;

    _loadRoles();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  // PHONE VALIDATION
  // =========================================================

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 7) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  // =========================================================
  // EMAIL VALIDATION
  // Tightened from the original regex: this version blocks
  // leading/trailing dots and consecutive dots in the local
  // part (e.g. ".john@x.com" or "jo..hn@x.com"), which the
  // previous pattern allowed through.
  // =========================================================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmed = value.trim();

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9](?:[a-zA-Z0-9._%+-]*[a-zA-Z0-9])?@[a-zA-Z0-9](?:[a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }

    if (trimmed.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }

    return null;
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loadingRoles = true;
    });

    try {
      final api = ApiService();

      final roles = await api.getRoles();

      if (!mounted) return;

      setState(() {
        _roles = roles.where((role) => role.isActive).toList();

        // Current user's role list-ல் இருக்கிறதா?
        final currentRole = _roles.where(
          (role) => role.id == widget.profile.role.id,
        );

        if (currentRole.isNotEmpty) {
          _role = currentRole.first;
        }
      });
    } catch (e) {
      debugPrint('LOAD ROLES ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingRoles = false;
        });
      }
    }
  }

  // =========================================================
  // COUNTRY PICKER — searchable, scrollable bottom sheet
  // =========================================================

  Future<void> _openCountryPicker() async {
    final selected = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CountryPickerSheet(),
    );

    if (selected != null && mounted) {
      setState(() => _selectedCountry = selected);
    }
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final fullPhone = '${_selectedCountry.dialCode} ${_phoneCtrl.text.trim()}';

    final updated = widget.profile.copyWith(
      phoneNumber: fullPhone,
      email: _emailCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      role: _role,
    );

    // Simulate save operation
    //await Future.delayed(const Duration(milliseconds: 150));

    final api = ApiService();

    final response = await api.updateProfile({
      'phone': fullPhone,
      'email': _emailCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'role': _role.value,
    });

    if (!mounted) return;

    Navigator.of(context).pop(updated);
  }

  // =========================================================
  // FIELD STYLE  (matches Edit Asset field decoration)
  // =========================================================

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF202A32),

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

      labelText: null,
      hintText: null,

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
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }

  // =========================================================
  // SMALL LABEL ABOVE FIELD (sized to match Edit Asset labels)
  // =========================================================

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _profileTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: AppColors.primaryBlue,
          decoration: _fieldDecoration(),
        ),
      ],
    );
  }

  // =========================================================
  // PHONE ROW — country selector (flag + dial code) + number
  // =========================================================

  Widget _phoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Phone Number'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _saving ? null : _openCountryPicker,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF202A32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountry.flag,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedCountry.dialCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 16,
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
                validator: _validatePhone,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                cursorColor: AppColors.primaryBlue,
                decoration: _fieldDecoration(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141D24),

      // Wider side margin so the card reads narrow like "Edit Asset",
      // not edge-to-edge.
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: ConstrainedBox(
        // Matches the Edit Asset popup width so both sheets feel consistent.
        constraints: const BoxConstraints(maxWidth: 320),

        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),

          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =================================================
                  // TITLE
                  // =================================================
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // PHONE NUMBER (country picker + number)
                  // =================================================
                  _phoneField(),

                  const SizedBox(height: 12),

                  // =================================================
                  // EMAIL ADDRESS
                  // =================================================
                  _profileTextField(
                    label: 'Email Address',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // LOCATION
                  // =================================================
                  _profileTextField(
                    label: 'Location',
                    controller: _locationCtrl,
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // POSITION
                  // =================================================
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Position'),
                      DropdownButtonFormField<RoleModel>(
                        initialValue:
                            _roles.any((role) => role.value == _role.value)
                            ? _roles.firstWhere(
                                (role) => role.value == _role.value,
                              )
                            : null,

                        dropdownColor: const Color(0xFF202A32),

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),

                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                          size: 18,
                        ),

                        decoration: _fieldDecoration(),

                        items: _roles.map((role) {
                          return DropdownMenuItem<RoleModel>(
                            value: role,
                            child: Text(
                              role.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),

                        onChanged: (_saving || _loadingRoles)
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _role = value;
                                  });
                                }
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // BUTTONS
                  // =================================================
                  Row(
                    children: [
                      // CANCEL
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(
                              color: Colors.white30,
                              width: 1,
                            ),
                            minimumSize: const Size(double.infinity, 40),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // SAVE CHANGES
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 40),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// COUNTRY PICKER SHEET — search box + scrollable country list
// =========================================================

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Country> get _filtered {
    if (_query.trim().isEmpty) return _countries;
    final q = _query.trim().toLowerCase();
    return _countries
        .where(
          (c) => c.name.toLowerCase().contains(q) || c.dialCode.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141D24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select Country',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  cursorColor: AppColors.primaryBlue,
                  decoration: InputDecoration(
                    hintText: 'Search country or code',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white38,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF202A32),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching country',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final country = _filtered[index];
                          return ListTile(
                            leading: Text(
                              country.flag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            title: Text(
                              country.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                              ),
                            ),
                            trailing: Text(
                              country.dialCode,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(country),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
