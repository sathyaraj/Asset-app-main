/// ============================================================
/// ROLE MODEL
/// ============================================================

class RoleModel {
  final int id;
  final String name;
  final String value;
  final bool isActive;

  const RoleModel({
    required this.id,
    required this.name,
    required this.value,
    this.isActive = true,
  });

  /// ==========================================================
  /// FROM JSON
  /// ==========================================================

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: int.tryParse(
            json['id']?.toString() ?? '0',
          ) ??
          0,

      name: json['name']?.toString() ?? '',

      value: json['value']?.toString() ?? '',

      isActive: _toBool(json['is_active']),
    );
  }

  /// ==========================================================
  /// TO JSON
  /// ==========================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// ==========================================================
  /// COPY WITH
  /// ==========================================================

  RoleModel copyWith({
    int? id,
    String? name,
    String? value,
    bool? isActive,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      isActive: isActive ?? this.isActive,
    );
  }

  /// ==========================================================
  /// BOOLEAN CONVERTER
  /// ==========================================================

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes';
    }

    return false;
  }

  /// ==========================================================
  /// DEBUG / DISPLAY
  /// ==========================================================

  @override
  String toString() {
    return 'RoleModel('
        'id: $id, '
        'name: $name, '
        'value: $value, '
        'isActive: $isActive'
        ')';
  }
}
