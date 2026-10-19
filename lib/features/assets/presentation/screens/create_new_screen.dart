import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assets_app/core/utils/app_colors.dart';
import 'package:assets_app/core/utils/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateNewScreen extends ConsumerStatefulWidget {
  const CreateNewScreen({super.key});

  @override
  ConsumerState<CreateNewScreen> createState() => _CreateNewScreenState();
}

// Which source the "Asset Photo" bottom sheet was answered with.
enum _AssetPhotoSource { camera, gallery }

class _AssetImage {
  final Uint8List bytes;
  final String name;
  final DateTime takenAt;
  final bool isExact;

  _AssetImage({
    required this.bytes,
    required this.name,
    required this.takenAt,
    required this.isExact,
  });
}

class _CreateNewScreenState extends ConsumerState<CreateNewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _assetFormKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  // Track which fields user has interacted with for inline validation
  final Set<String> _interactedFields = {};

  String? _assetLocationId;

  final _assetCodeController = TextEditingController();
  final _assetDescriptionController = TextEditingController();
  final _assetQuantityController = TextEditingController(text: '1');
  final _assetNameController = TextEditingController();
  final _purchaseCostController = TextEditingController();
  final _commentsController = TextEditingController();

  String? _assetSystem;
  String? _assetTag;
  String? _assetType;
  String? _assetGroup;
  String? _assetClassification;
  String? _assetCondition;
  String? _productCode;
  String? _modelType;
  String? _manufacturerName;
  DateTime? _purchaseDate;

  // Warranty Expiry Date only
  DateTime? _warrantyExpiryDate;

  String? _supplierName;
  String? _costCenterName;

  // ============================================================
  // ASSET STATUS / PHOTO
  // ============================================================

  String _assetStatus = 'ACTIVE';

  final List<_AssetImage> _assetImages = [];
  static const int _maxImages = 5;

  // ============================================================
  // LOCATION FORM FIELDS
  // ============================================================

  String? _locationType;
  String? _siteName;
  String? _buildingName;
  String? _areaZone;
  String? _floor;
  String? _roomName;
  String? _roomNumber;
  String? _condition;
  String? _code;
  String? _criticality;

  // ============================================================
  // DROPDOWN OPTIONS
  // ============================================================

  Map<String, List<Map<String, String>>> _locationOptions = {};

  Map<String, List<String>> _dropdownOptions = {};

  Map<String, List<String>> _assetDropdownOptions = {};

  bool _isLoadingOptions = true;
  bool _isLoadingAssetOptions = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _fetchDropdownOptions();
    _fetchAssetDropdownOptions();
  }

  // ============================================================
  // FETCH LOCATION DROPDOWNS
  // ============================================================
  //
  // Supports BOTH response formats:
  //
  // 1. List:
  // data: [
  //   {
  //     "id": 13,
  //     "category": "area_zone",
  //     "label": "Central Plaza",
  //     "value": "Central Plaza"
  //   }
  // ]
  //
  // 2. Map:
  // data: {
  //   "area_zone": [
  //     {"label": "...", "value": "..."}
  //   ]
  // }
  //
  // ============================================================

  Future<void> _fetchDropdownOptions() async {
    try {
      final response = await ref
          .read(apiServiceProvider)
          .getDropdownOptions(page: 1, limit: 100);

      debugPrint('LOCATION DROPDOWN RESPONSE: $response');

      if (response['status'] == 'success' || response['success'] == true) {
        final dynamic rawData = response['data'];

        final Map<String, List<String>> options = {};

        if (rawData is List) {
          for (final item in rawData) {
            if (item is! Map) {
              continue;
            }

            final String category = item['category']?.toString().trim() ?? '';

            final String value =
                item['value']?.toString().trim() ??
                item['label']?.toString().trim() ??
                '';

            if (category.isEmpty || value.isEmpty) {
              continue;
            }

            options.putIfAbsent(category, () => []);

            if (!options[category]!.contains(value)) {
              options[category]!.add(value);
            }
          }
        } else if (rawData is Map) {
          rawData.forEach((key, value) {
            if (value is! List) {
              return;
            }

            final List<String> values = [];

            for (final item in value) {
              String itemValue = '';

              if (item is Map) {
                itemValue =
                    item['value']?.toString().trim() ??
                    item['label']?.toString().trim() ??
                    '';
              } else {
                itemValue = item.toString().trim();
              }

              if (itemValue.isNotEmpty && !values.contains(itemValue)) {
                values.add(itemValue);
              }
            }

            if (values.isNotEmpty) {
              options[key.toString()] = values;
            }
          });
        }

        debugPrint('LOCATION DROPDOWN CATEGORIES: ${options.keys.toList()}');

        debugPrint('LOCATION DROPDOWN OPTIONS: $options');

        if (mounted) {
          setState(() {
            _dropdownOptions = options;
            _isLoadingOptions = false;
          });
        }
      } else {
        debugPrint(
          'LOCATION DROPDOWN API ERROR: '
          '${response['message'] ?? 'Unknown error'}',
        );

        if (mounted) {
          setState(() {
            _dropdownOptions = {};
            _isLoadingOptions = false;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching location dropdowns: $e');

      debugPrint('LOCATION DROPDOWN STACKTRACE: $stackTrace');

      if (mounted) {
        setState(() {
          _dropdownOptions = {};
          _isLoadingOptions = false;
        });
      }
    }
  }

  // ============================================================
  // FETCH ASSET DROPDOWNS
  // ============================================================

  Future<void> _fetchAssetDropdownOptions() async {
    try {
      final response = await ref.read(apiServiceProvider).getAssetDropdowns();

      debugPrint('ASSET DROPDOWN RESPONSE: ${response.data}');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final dynamic rawData = response.data['data'];

        final Map<String, List<String>> options = {};

        if (rawData is Map) {
          rawData.forEach((key, value) {
            if (key != 'locations' && value is List) {
              final List<String> values = [];

              for (final item in value) {
                if (item is Map) {
                  final String itemValue =
                      item['value']?.toString().trim() ??
                      item['label']?.toString().trim() ??
                      '';

                  if (itemValue.isNotEmpty && !values.contains(itemValue)) {
                    values.add(itemValue);
                  }
                } else {
                  final String itemValue = item.toString().trim();

                  if (itemValue.isNotEmpty && !values.contains(itemValue)) {
                    values.add(itemValue);
                  }
                }
              }

              if (values.isNotEmpty) {
                options[key.toString()] = values;
              }
            }
          });
        }

        final List<Map<String, String>> locations = [];

        if (rawData is Map && rawData['locations'] is List) {
          for (final item in rawData['locations']) {
            if (item is Map) {
              final String label = item['label']?.toString().trim() ?? '';

              final String value = item['value']?.toString().trim() ?? '';

              if (label.isNotEmpty || value.isNotEmpty) {
                locations.add({'label': label, 'value': value});
              }
            }
          }
        }

        debugPrint('ASSET DROPDOWN CATEGORIES: ${options.keys.toList()}');

        debugPrint('ASSET LOCATIONS: $locations');

        if (mounted) {
          setState(() {
            _assetDropdownOptions = options;
            _locationOptions = {'locations': locations};
            _isLoadingAssetOptions = false;
          });
        }
      } else {
        debugPrint(
          'ASSET DROPDOWN API ERROR: '
          '${response.data['message'] ?? 'Unknown error'}',
        );

        if (mounted) {
          setState(() {
            _assetDropdownOptions = {};
            _locationOptions = {'locations': []};
            _isLoadingAssetOptions = false;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching asset dropdowns: $e');

      debugPrint('ASSET DROPDOWN STACKTRACE: $stackTrace');

      if (mounted) {
        setState(() {
          _assetDropdownOptions = {};
          _locationOptions = {'locations': []};
          _isLoadingAssetOptions = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tabController.dispose();

    _assetCodeController.dispose();
    _assetDescriptionController.dispose();
    _assetQuantityController.dispose();
    _assetNameController.dispose();
    _purchaseCostController.dispose();
    _commentsController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        title: Text(
          'Create New',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ImportExcelButton(onTap: _handleImportTap),
          ),
        ],

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Location'),
            Tab(text: 'Asset'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [_buildLocationTab(), _buildAssetTab()],
      ),
    );
  }

  // ============================================================
  // LOCATION TAB
  // ============================================================

  Widget _buildLocationTab() {
    if (_isLoadingOptions) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),

      child: Form(
        key: _formKey,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            _buildDropdownField(
              'Location Type',
              _locationType,
              'location_type',
              (val) {
                setState(() {
                  _locationType = val;
                });
              },
              icon: Icons.category_outlined,
            ),

            _buildDropdownField(
              'Site Name / Project Name',
              _siteName,
              'site_name',
              (val) {
                setState(() {
                  _siteName = val;
                });
              },
              icon: Icons.apartment_outlined,
            ),

            _buildDropdownField(
              'Building Name / Number',
              _buildingName,
              'building_name',
              (val) {
                setState(() {
                  _buildingName = val;
                });
              },
              icon: Icons.location_city_outlined,
            ),

            _buildDropdownField('Area/Zone', _areaZone, 'area_zone', (val) {
              setState(() {
                _areaZone = val;
              });
            }, icon: Icons.map_outlined),

            _buildDropdownField('Floor', _floor, 'floor', (val) {
              setState(() {
                _floor = val;
              });
            }, icon: Icons.layers_outlined),

            _buildDropdownField('Room Name', _roomName, 'room_name', (val) {
              setState(() {
                _roomName = val;
              });
            }, icon: Icons.meeting_room_outlined),

            _buildDropdownField('Room Number', _roomNumber, 'room_number', (
              val,
            ) {
              setState(() {
                _roomNumber = val;
              });
            }, icon: Icons.tag),

            _buildDropdownField(
              'Location - Condition',
              _condition,
              'location_condition',
              (val) {
                setState(() {
                  _condition = val;
                });
              },
              icon: Icons.build_circle_outlined,
            ),

            _buildDropdownField(
              'Location - Code',
              _code,
              'location_code',
              (val) {
                setState(() {
                  _code = val;
                });
              },
              icon: Icons.qr_code_2_outlined,
            ),

            _buildCriticalityDropdown(),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLocation,

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.5),
              ),

              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Location',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CRITICALITY DROPDOWN
  // ============================================================

  Widget _buildCriticalityDropdown() {
    List<String> criticalityOptions = [];

    if (_dropdownOptions.containsKey('location_criticality')) {
      criticalityOptions = _dropdownOptions['location_criticality'] ?? [];
    }

    if (criticalityOptions.isEmpty &&
        _dropdownOptions.containsKey('criticality')) {
      criticalityOptions = _dropdownOptions['criticality'] ?? [];
    }

    criticalityOptions = criticalityOptions.toSet().toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Location - Criticality',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                setState(() => _interactedFields.add('Location - Criticality'));

                _formKey.currentState?.validate();
              }
            },

            child: DropdownButtonFormField<String>(
              value: criticalityOptions.contains(_criticality)
                  ? _criticality
                  : null,

              dropdownColor: AppColors.cardBackground,

              style: const TextStyle(color: Colors.white),

              autovalidateMode: AutovalidateMode.onUserInteraction,

              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.priority_high_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),

                filled: true,

                fillColor: AppColors.cardBackground,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),

                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),

                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),

              hint: const Text(
                'Select Criticality',
                style: TextStyle(color: Colors.grey),
              ),

              items: criticalityOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),

              onChanged: criticalityOptions.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        _interactedFields.add('Location - Criticality');
                        _criticality = value;
                      });

                      _formKey.currentState?.validate();
                    },

              validator: (value) {
                if (!_interactedFields.contains('Location - Criticality')) {
                  return null;
                }

                if (value == null || value.isEmpty) {
                  return 'Criticality is required';
                }

                return null;
              },
            ),
          ),

          if (criticalityOptions.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'No criticality options available',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ASSET TAB
  // ============================================================

  Widget _buildAssetTab() {
    if (_isLoadingAssetOptions) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),

      child: Form(
        key: _assetFormKey,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            _buildAssetDropdownField(
              'Location',
              _assetLocationId,
              'locations',
              (val) {
                setState(() {
                  _assetLocationId = val;
                });
              },
              isLocation: true,
              icon: Icons.location_on_outlined,
            ),

            _buildImageUploadField(),

            _buildTextField(
              'Asset Name',
              _assetNameController,
              icon: Icons.title,
            ),

            _buildTextField(
              'Asset Code',
              _assetCodeController,
              icon: Icons.qr_code,
            ),

            _buildTextField(
              'Asset Description',
              _assetDescriptionController,
              maxLines: 2,
              icon: Icons.description,
            ),

            _buildTextField(
              'Quantity',
              _assetQuantityController,
              keyboardType: TextInputType.number,
              icon: Icons.inventory,
            ),

            _buildAssetDropdownField(
              'Asset Master Category',
              _assetSystem,
              'system',
              (val) {
                setState(() {
                  _assetSystem = val;
                });
              },
              icon: Icons.category_outlined,
            ),

            _buildAssetDropdownField('Asset Tag', _assetTag, 'tag', (val) {
              setState(() {
                _assetTag = val;
              });
            }, icon: Icons.local_offer_outlined),

            _buildAssetDropdownField('Asset Type', _assetType, 'type', (val) {
              setState(() {
                _assetType = val;
              });
            }, icon: Icons.devices_other_outlined),

            _buildAssetDropdownField(
              'Asset Group',
              _assetGroup,
              'group_name',
              (val) {
                setState(() {
                  _assetGroup = val;
                });
              },
              icon: Icons.group_work_outlined,
            ),

            _buildAssetDropdownField(
              'Asset Classification',
              _assetClassification,
              'classification',
              (val) {
                setState(() {
                  _assetClassification = val;
                });
              },
              icon: Icons.class_outlined,
            ),

            _buildAssetDropdownField(
              'Condition',
              _assetCondition,
              'condition',
              (val) {
                setState(() {
                  _assetCondition = val;
                });
              },
              icon: Icons.health_and_safety_outlined,
            ),

            _buildStaticDropdownField(
              'Asset Status',
              _assetStatus,
              _assetDropdownOptions['status']?.isNotEmpty == true
                  ? _assetDropdownOptions['status']!
                  : const ['ACTIVE', 'MAINTENANCE', 'STORED', 'DISPOSED'],
              (val) {
                setState(() {
                  _assetStatus = val ?? 'ACTIVE';
                });
              },
              icon: Icons.toggle_on_outlined,
            ),

            _buildAssetDropdownField(
              'Product Code',
              _productCode,
              'product_code',
              (val) {
                setState(() {
                  _productCode = val;
                });
              },
              icon: Icons.qr_code_2_outlined,
            ),

            _buildAssetDropdownField('Model Type', _modelType, 'model_type', (
              val,
            ) {
              setState(() {
                _modelType = val;
              });
            }, icon: Icons.devices_outlined),

            _buildAssetDropdownField(
              'Manufacturer Name',
              _manufacturerName,
              'manufacturer',
              (val) {
                setState(() {
                  _manufacturerName = val;
                });
              },
              icon: Icons.factory_outlined,
            ),

            _buildDatePickerField('Purchase Date', _purchaseDate, (date) {
              setState(() {
                _purchaseDate = date;

                if (_warrantyExpiryDate != null &&
                    _warrantyExpiryDate!.isBefore(date)) {
                  _warrantyExpiryDate = null;
                }
              });
            }),

            _buildWarrantyExpiryDateField(),

            _buildTextField(
              'Purchase Cost',
              _purchaseCostController,
              keyboardType: TextInputType.number,
              icon: Icons.attach_money,
            ),

            _buildAssetDropdownField(
              'Supplier Name',
              _supplierName,
              'supplier',
              (val) {
                setState(() {
                  _supplierName = val;
                });
              },
              icon: Icons.local_shipping_outlined,
            ),

            _buildAssetDropdownField(
              'Cost Center Name',
              _costCenterName,
              'cost_center',
              (val) {
                setState(() {
                  _costCenterName = val;
                });
              },
              icon: Icons.account_balance_outlined,
            ),

            _buildTextField(
              'Comments',
              _commentsController,
              maxLines: 3,
              icon: Icons.comment,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAsset,

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.5),
              ),

              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Asset',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WARRANTY EXPIRY DATE
  // ============================================================

  Widget _buildWarrantyExpiryDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Warranty Expiry Date',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          InkWell(
            borderRadius: BorderRadius.circular(12),

            onTap: () async {
              DateTime initialDate =
                  _warrantyExpiryDate ?? (_purchaseDate ?? DateTime.now());

              final DateTime firstDate = _purchaseDate ?? DateTime(2000);

              if (initialDate.isBefore(firstDate)) {
                initialDate = firstDate;
              }

              final DateTime? date = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: DateTime(2100),
                helpText: 'SELECT WARRANTY EXPIRY DATE',
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: AppColors.cardBackground,
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: AppColors.background,
                    ),
                    child: child!,
                  );
                },
              );

              if (date != null) {
                setState(() {
                  _warrantyExpiryDate = date;
                });
              }
            },

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_available_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _warrantyExpiryDate == null
                            ? 'Select Date'
                            : _formatDate(_warrantyExpiryDate!),
                        style: TextStyle(
                          color: _warrantyExpiryDate == null
                              ? Colors.grey
                              : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_warrantyExpiryDate != null &&
              _purchaseDate != null &&
              _warrantyExpiryDate!.isBefore(_purchaseDate!))
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Warranty Expiry Date cannot be before Purchase Date.',
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    final bool isOptional = label == 'Comments';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                setState(() {
                  _interactedFields.add(label);
                });

                _assetFormKey.currentState?.validate();

                _formKey.currentState?.validate();
              }
            },

            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white),
              autovalidateMode: AutovalidateMode.onUserInteraction,

              onChanged: (v) {
                _interactedFields.add(label);

                _assetFormKey.currentState?.validate();
              },

              onTapOutside: (_) {
                _interactedFields.add(label);

                _assetFormKey.currentState?.validate();
              },

              decoration: InputDecoration(
                prefixIcon: icon != null
                    ? Icon(
                        icon,
                        color: AppColors.primary.withOpacity(0.5),
                        size: 20,
                      )
                    : null,

                filled: true,

                fillColor: AppColors.cardBackground,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),

                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),

                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),

              validator: (val) {
                if (!_interactedFields.contains(label)) {
                  return null;
                }

                final v = val?.trim() ?? '';

                if (isOptional) {
                  return null;
                }

                if (v.isEmpty) {
                  return '$label is required';
                }

                if (label == 'Quantity') {
                  final n = int.tryParse(v);

                  if (n == null) {
                    return 'Enter numbers only';
                  }

                  if (n <= 0) {
                    return 'Quantity must be at least 1';
                  }
                }

                if (label == 'Purchase Cost') {
                  final n = double.tryParse(v);

                  if (n == null) {
                    return 'Enter valid amount';
                  }

                  if (n < 0) {
                    return 'Cost cannot be negative';
                  }
                }

                if (label == 'Asset Code' && v.length < 2) {
                  return 'Asset Code too short';
                }

                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Widget _buildDatePickerField(
    String label,
    DateTime? value,
    Function(DateTime) onDateSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          InkWell(
            onTap: () async {
              final DateTime today = DateTime.now();

              final DateTime maxDate = DateTime(
                today.year,
                today.month,
                today.day,
              );

              DateTime initialDate = value ?? maxDate;

              if (initialDate.isAfter(maxDate)) {
                initialDate = maxDate;
              }

              final DateTime? date = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: maxDate,

                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: AppColors.cardBackground,
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: AppColors.background,
                  ),
                  child: child!,
                ),
              );

              if (date != null) {
                onDateSelected(date);
              }
            },

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    value == null ? 'Select Date' : _formatDate(value),
                    style: const TextStyle(color: Colors.white),
                  ),

                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ASSET DROPDOWN
  // ============================================================

  Widget _buildAssetDropdownField(
    String label,
    String? value,
    String category,
    Function(String?) onChanged, {
    bool isLocation = false,
    IconData? icon,
  }) {
    final List<Map<String, String>> options = [];

    if (isLocation) {
      options.addAll(_locationOptions['locations'] ?? []);
    } else {
      final values = _assetDropdownOptions[category] ?? [];

      for (final item in values) {
        options.add({'label': item, 'value': item});
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                setState(() {
                  _interactedFields.add(label);
                });

                _assetFormKey.currentState?.validate();

                _formKey.currentState?.validate();
              }
            },

            child: DropdownButtonFormField<String>(
              value: options.any((e) => e['value'] == value) ? value : null,

              dropdownColor: AppColors.cardBackground,

              style: const TextStyle(color: Colors.white),

              autovalidateMode: AutovalidateMode.onUserInteraction,

              decoration: InputDecoration(
                prefixIcon: icon != null
                    ? Icon(
                        icon,
                        color: AppColors.primary.withOpacity(0.5),
                        size: 20,
                      )
                    : null,

                filled: true,

                fillColor: AppColors.cardBackground,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),

                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),

                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),

              hint: Text(
                'Select $label',
                style: const TextStyle(color: Colors.grey),
              ),

              items: options.map((e) {
                return DropdownMenuItem<String>(
                  value: e['value'],
                  child: Text(
                    e['label'] ?? '',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),

              onChanged: options.isEmpty
                  ? null
                  : (val) {
                      setState(() {
                        _interactedFields.add(label);
                      });

                      _assetFormKey.currentState?.validate();

                      onChanged(val);
                    },

              validator: (val) {
                if (!_interactedFields.contains(label)) {
                  return null;
                }

                if (val == null || val.isEmpty) {
                  return '$label is required';
                }

                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATIC DROPDOWN
  // ============================================================

  Widget _buildStaticDropdownField(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                setState(() {
                  _interactedFields.add(label);
                });

                _assetFormKey.currentState?.validate();
              }
            },

            child: DropdownButtonFormField<String>(
              value: options.contains(value) ? value : null,

              dropdownColor: AppColors.cardBackground,

              style: const TextStyle(color: Colors.white),

              autovalidateMode: AutovalidateMode.onUserInteraction,

              decoration: InputDecoration(
                prefixIcon: icon != null
                    ? Icon(
                        icon,
                        color: AppColors.primary.withOpacity(0.5),
                        size: 20,
                      )
                    : null,

                filled: true,

                fillColor: AppColors.cardBackground,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),

                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),

                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),

              hint: Text(
                'Select $label',
                style: const TextStyle(color: Colors.grey),
              ),

              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),

              onChanged: (val) {
                setState(() {
                  _interactedFields.add(label);
                });

                _assetFormKey.currentState?.validate();

                onChanged(val);
              },

              validator: (val) {
                if (!_interactedFields.contains(label)) {
                  return null;
                }

                if (val == null || val.isEmpty) {
                  return '$label is required';
                }

                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ASSET PHOTO
  // ============================================================

  Future<void> _showImageSourceSheet() async {
    if (!mounted) return;

    final source = await showModalBottomSheet<_AssetPhotoSource>(
      context: context,
      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: Colors.amber,
                        size: 18,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          'Photo must have date/time token (EXIF) — otherwise rejected',
                          style: GoogleFonts.outfit(
                            color: Colors.amber.shade200,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primary,
                  ),

                  title: const Text(
                    'Take Photo with Camera',
                    style: TextStyle(color: Colors.white),
                  ),

                  subtitle: const Text(
                    'Live capture with date token required',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),

                  onTap: () =>
                      Navigator.of(sheetContext).pop(_AssetPhotoSource.camera),
                ),

                const Divider(height: 1, color: Colors.white10),

                ListTile(
                  leading: const Icon(
                    Icons.folder_open_outlined,
                    color: AppColors.primary,
                  ),

                  title: const Text(
                    'Choose from Gallery (JPEG/PNG)',
                    style: TextStyle(color: Colors.white),
                  ),

                  subtitle: const Text(
                    'Must have EXIF date/time token — otherwise rejected',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),

                  onTap: () =>
                      Navigator.of(sheetContext).pop(_AssetPhotoSource.gallery),
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    if (source == _AssetPhotoSource.camera) {
      await _pickAssetImageFromCamera();
    } else {
      await _pickAssetImageFromFiles();
    }
  }

  Future<void> _pickAssetImageFromCamera() async {
    if (_assetImages.length >= _maxImages) {
      _showError('Maximum $_maxImages images allowed.');
      return;
    }

    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();

      final DateTime? exifDate = await _extractExifDateTaken(bytes);

      if (exifDate == null) {
        if (mounted) {
          _showError(
            'Image rejected — no capture date token (EXIF) found. Use original camera photo with location/date enabled.',
          );
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        _assetImages.add(
          _AssetImage(
            bytes: bytes,
            name: photo.name,
            takenAt: exifDate,
            isExact: true,
          ),
        );
      });
    } catch (e) {
      _showError('Could not open the camera: $e');
    }
  }

  Future<void> _pickAssetImageFromFiles() async {
    if (_assetImages.length >= _maxImages) {
      _showError('Maximum $_maxImages images allowed.');
      return;
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    for (final f in result.files) {
      if (_assetImages.length >= _maxImages) {
        _showError('Maximum $_maxImages images — some files skipped.');
        break;
      }

      if (f.bytes == null) continue;

      final Uint8List bytes = f.bytes!;

      final DateTime? exifDate = await _extractExifDateTaken(bytes);

      if (exifDate == null) {
        if (mounted) {
          _showError('Image ${f.name} rejected — no date/time token (EXIF).');
        }
        continue;
      }

      if (!mounted) return;

      setState(() {
        _assetImages.add(
          _AssetImage(
            bytes: bytes,
            name: f.name,
            takenAt: exifDate,
            isExact: true,
          ),
        );
      });
    }
  }

  Future<DateTime?> _extractExifDateTaken(Uint8List bytes) async {
    try {
      final Map<String, IfdTag> data = await readExifFromBytes(bytes);

      if (data.isEmpty) return null;

      final IfdTag? tag =
          data['EXIF DateTimeOriginal'] ?? data['Image DateTime'];

      if (tag == null) return null;

      final raw = tag.printable.trim();

      final parts = raw.split(' ');

      if (parts.isEmpty) return null;

      final datePart = parts[0].replaceAll(':', '-');

      final timePart = parts.length > 1 ? parts[1] : '00:00:00';

      return DateTime.tryParse('$datePart $timePart');
    } catch (e) {
      debugPrint('EXIF read error: $e');

      return null;
    }
  }

  void _removeAssetImage(int index) {
    setState(() {
      if (index >= 0 && index < _assetImages.length) {
        _assetImages.removeAt(index);
      }
    });
  }

  String _formatDateTime(DateTime date) {
    final h24 = date.hour;
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;

    return '${_formatDate(date)} '
        '${h12.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')} '
        '$period';
  }

  Widget _buildImageUploadField() {
    final bool canAdd = _assetImages.length < _maxImages;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Text(
                'Asset Photos',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                decoration: BoxDecoration(
                  color: _assetImages.isEmpty
                      ? Colors.white10
                      : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),

                child: Text(
                  '${_assetImages.length}/$_maxImages',
                  style: TextStyle(
                    color: _assetImages.isEmpty
                        ? Colors.grey
                        : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Spacer(),

              if (_assetImages.isNotEmpty)
                Text(
                  'Tap + for more',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          if (_assetImages.isEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showImageSourceSheet,

              child: Container(
                width: double.infinity,
                height: 100,

                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),

                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary.withOpacity(0.6),
                        size: 26,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Tap for camera or gallery — date/time token required',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Max $_maxImages photos',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 118,

              child: ListView.separated(
                scrollDirection: Axis.horizontal,

                itemCount: _assetImages.length + (canAdd ? 1 : 0),

                separatorBuilder: (_, __) => const SizedBox(width: 10),

                itemBuilder: (context, index) {
                  if (index == _assetImages.length && canAdd) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showImageSourceSheet,

                      child: Container(
                        width: 110,
                        height: 118,

                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),

                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons.add,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Add photo',
                              style: GoogleFonts.outfit(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            Text(
                              '${_assetImages.length}/$_maxImages',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final img = _assetImages[index];

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: Image.memory(
                          img.bytes,
                          width: 110,
                          height: 118,
                          fit: BoxFit.cover,
                        ),
                      ),

                      Positioned(
                        top: 5,
                        right: 5,

                        child: InkWell(
                          onTap: () => _removeAssetImage(index),

                          child: Container(
                            padding: const EdgeInsets.all(4),

                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),

                      if (canAdd)
                        Positioned(
                          bottom: 5,
                          right: 5,

                          child: InkWell(
                            onTap: _showImageSourceSheet,

                            child: Container(
                              padding: const EdgeInsets.all(5),

                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),

                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        bottom: 5,
                        left: 5,

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Icon(
                                Icons.schedule,
                                size: 10,
                                color: img.isExact
                                    ? Colors.greenAccent
                                    : Colors.amber.shade300,
                              ),

                              const SizedBox(width: 3),

                              Text(
                                img.isExact
                                    ? _formatDate(img.takenAt)
                                    : 'No token',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          if (_assetImages.isNotEmpty) ...[
            const SizedBox(height: 8),

            ...List.generate(_assetImages.length, (i) {
              final img = _assetImages[i];

              return Padding(
                padding: const EdgeInsets.only(top: 3, left: 4),

                child: Row(
                  children: [
                    Text(
                      '${i + 1}. ',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),

                    Icon(
                      Icons.schedule,
                      size: 11,
                      color: img.isExact
                          ? AppColors.primary.withOpacity(0.7)
                          : Colors.amber.shade300,
                    ),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        '${img.name} — Taken: ${_formatDateTime(img.takenAt)}',
                        style: TextStyle(
                          color: img.isExact
                              ? Colors.white54
                              : Colors.amber.shade200,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT ASSET
  // ============================================================

  Future<void> _submitAsset() async {
    _interactedFields.addAll([
      'Location',
      'Asset Name',
      'Asset Code',
      'Asset Description',
      'Quantity',
      'Asset Master Category',
      'Asset Tag',
      'Asset Type',
      'Asset Group',
      'Asset Classification',
      'Condition',
      'Asset Status',
      'Product Code',
      'Model Type',
      'Manufacturer Name',
      'Supplier Name',
      'Cost Center Name',
      'Purchase Cost',
      'Comments',
    ]);

    setState(() {});

    if (!_assetFormKey.currentState!.validate()) {
      return;
    }

    if (_warrantyExpiryDate != null &&
        _purchaseDate != null &&
        _warrantyExpiryDate!.isBefore(_purchaseDate!)) {
      _showError('Warranty Expiry Date cannot be before Purchase Date.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final api = ref.read(apiServiceProvider);

      final response = await api.createAsset(_buildAssetPayload());

      if (response.statusCode == 201 && response.data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asset saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save asset');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD ASSET PAYLOAD
  // ============================================================

  Map<String, dynamic> _buildAssetPayload() {
    return {
      'location_id': _assetLocationId,

      'asset_name': _assetNameController.text,

      'asset_code': _assetCodeController.text,

      'description': _assetDescriptionController.text,

      'quantity': int.tryParse(_assetQuantityController.text) ?? 1,

      'system': _assetSystem,

      'tag': _assetTag,

      'type': _assetType,

      'group_name': _assetGroup,

      'classification': _assetClassification,

      'asset_condition': _assetCondition,

      'product_code': _productCode,

      'model_type': _modelType,

      'manufacturer': _manufacturerName,

      'purchase_date': _purchaseDate != null
          ? _formatDate(_purchaseDate!)
          : null,

      'warranty_expiry_date': _warrantyExpiryDate != null
          ? _formatDate(_warrantyExpiryDate!)
          : null,

      'purchase_cost': double.tryParse(_purchaseCostController.text) ?? 0.0,

      'supplier': _supplierName,

      'cost_center': _costCenterName,

      'comments': _commentsController.text,

      'status': _assetStatus,

      if (_assetImages.isNotEmpty)
        'image_base64': base64Encode(_assetImages.first.bytes),

      if (_assetImages.isNotEmpty) 'image_name': _assetImages.first.name,

      if (_assetImages.isNotEmpty)
        'image_taken_at': _assetImages.first.takenAt.toIso8601String(),

      if (_assetImages.isNotEmpty) 'image_count': _assetImages.length,

      if (_assetImages.isNotEmpty)
        'images': _assetImages
            .map(
              (e) => {
                'image_base64': base64Encode(e.bytes),
                'image_name': e.name,
                'image_taken_at': e.takenAt.toIso8601String(),
              },
            )
            .toList(),

      'installed_time':
          "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:"
          "${TimeOfDay.now().minute.toString().padLeft(2, '0')} "
          "${TimeOfDay.now().period == DayPeriod.am ? 'AM' : 'PM'}",
    };
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ============================================================
  // LOCATION DROPDOWN
  // ============================================================

  Widget _buildDropdownField(
    String label,
    String? value,
    String category,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    final List<String> options = (_dropdownOptions[category] ?? [])
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                setState(() {
                  _interactedFields.add(label);
                });

                _formKey.currentState?.validate();
              }
            },

            child: DropdownButtonFormField<String>(
              value: options.contains(value) ? value : null,

              dropdownColor: AppColors.cardBackground,

              style: const TextStyle(color: Colors.white),

              autovalidateMode: AutovalidateMode.onUserInteraction,

              decoration: InputDecoration(
                prefixIcon: icon != null
                    ? Icon(
                        icon,
                        color: AppColors.primary.withOpacity(0.5),
                        size: 20,
                      )
                    : null,

                filled: true,

                fillColor: AppColors.cardBackground,

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),

                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.2,
                  ),
                ),

                errorStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),

              hint: Text(
                'Select $label',
                style: const TextStyle(color: Colors.grey),
              ),

              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),

              onChanged: options.isEmpty
                  ? null
                  : (val) {
                      setState(() {
                        _interactedFields.add(label);
                      });

                      _formKey.currentState?.validate();

                      onChanged(val);
                    },

              validator: (val) {
                if (!_interactedFields.contains(label)) {
                  return null;
                }

                if (val == null || val.isEmpty) {
                  return '$label is required';
                }

                return null;
              },
            ),
          ),

          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),

              child: Text(
                'No options available',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT LOCATION
  // ============================================================

  Future<void> _submitLocation() async {
    _interactedFields.addAll([
      'Location Type',
      'Site Name / Project Name',
      'Building Name / Number',
      'Area/Zone',
      'Floor',
      'Room Name',
      'Room Number',
      'Location - Condition',
      'Location - Code',
      'Location - Criticality',
    ]);

    setState(() {});

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final api = ref.read(apiServiceProvider);

      final response = await api.createLocation(_buildLocationPayload());

      debugPrint('CREATE LOCATION RESPONSE: ${response.data}');

      if (response.statusCode == 201 && response.data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to save location');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD LOCATION PAYLOAD
  // ============================================================

  Map<String, dynamic> _buildLocationPayload() {
    return {
      'location_type': _locationType,
      'site_name': _siteName,
      'building_name': _buildingName,
      'area_zone': _areaZone,
      'floor': _floor,
      'room_name': _roomName,
      'room_number': _roomNumber,
      'condition': _condition,
      'code': _code,
      'criticality': _criticality,
    };
  }

  // ============================================================
  // EXCEL BULK IMPORT
  // ============================================================

  static const Map<String, String> _locationHeaderMap = {
    'location type': 'location_type',
    'site name': 'site_name',
    'site name / project name': 'site_name',
    'building name': 'building_name',
    'building name / number': 'building_name',
    'area zone': 'area_zone',
    'area/zone': 'area_zone',
    'floor': 'floor',
    'room name': 'room_name',
    'room number': 'room_number',
    'condition': 'condition',
    'code': 'code',
    'criticality': 'criticality',
  };

  static const Map<String, String> _assetHeaderMap = {
    'asset name': 'asset_name',
    'asset code': 'asset_code',
    'description': 'description',
    'quantity': 'quantity',
    'system': 'system',
    'tag': 'tag',
    'type': 'type',
    'group': 'group_name',
    'group name': 'group_name',
    'classification': 'classification',
    'condition': 'asset_condition',
    'product code': 'product_code',
    'model type': 'model_type',
    'manufacturer': 'manufacturer',
    'purchase date': 'purchase_date',
    'warranty expiry date': 'warranty_expiry_date',
    'purchase cost': 'purchase_cost',
    'supplier': 'supplier',
    'cost center': 'cost_center',
    'comments': 'comments',
    'location id': 'location_id',
    'location': 'location_id',
    'status': 'status',
    'asset status': 'status',
  };

  bool get _isLocationTabActive => _tabController.index == 0;

  void _handleImportTap() {
    if (_isSubmitting) return;

    _pickAndPreviewExcel(forLocation: _isLocationTabActive);
  }

  // ============================================================
  // PICK AND PREVIEW EXCEL
  // ============================================================

  Future<void> _pickAndPreviewExcel({required bool forLocation}) async {
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (picked == null || picked.files.single.bytes == null) {
      return;
    }

    final Uint8List bytes = picked.files.single.bytes!;

    late final xls.Excel workbook;

    try {
      workbook = xls.Excel.decodeBytes(bytes);
    } catch (e) {
      _showError(
        'Could not read that file. Make sure it is a valid .xlsx file.',
      );
      return;
    }

    if (workbook.tables.isEmpty) {
      _showError('That spreadsheet has no sheets.');
      return;
    }

    final sheet = workbook.tables.values.first;

    if (sheet.maxRows < 2) {
      _showError('That sheet has no data rows below the header.');
      return;
    }

    final headerRow = sheet.row(0);

    final headers = headerRow
        .map((cell) => (cell?.value?.toString() ?? '').trim())
        .toList();

    final headerMap = forLocation ? _locationHeaderMap : _assetHeaderMap;

    final List<String?> columnFieldKeys = headers.map((h) {
      final normalized = h.toLowerCase().trim();

      return headerMap[normalized];
    }).toList();

    final unrecognizedHeaders = <String>[];

    for (int i = 0; i < headers.length; i++) {
      if (headers[i].isNotEmpty && columnFieldKeys[i] == null) {
        unrecognizedHeaders.add(headers[i]);
      }
    }

    final List<Map<String, dynamic>> rows = [];

    for (int r = 1; r < sheet.maxRows; r++) {
      final row = sheet.row(r);

      final isBlank = row.every(
        (cell) =>
            cell == null || (cell.value?.toString().trim().isEmpty ?? true),
      );

      if (isBlank) continue;

      final Map<String, dynamic> parsedRow = {};

      for (int c = 0; c < row.length && c < columnFieldKeys.length; c++) {
        final key = columnFieldKeys[c];

        if (key == null) continue;

        final cell = row[c];

        parsedRow[key] = cell?.value?.toString().trim();
      }

      rows.add(parsedRow);
    }

    if (rows.isEmpty) {
      _showError('No usable data rows were found in that sheet.');
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (_) => _ExcelImportPreviewSheet(
        forLocation: forLocation,
        fileName: picked.files.single.name,
        rows: rows,
        unrecognizedHeaders: unrecognizedHeaders,

        onConfirmImport: (rows) =>
            _runBulkImport(rows: rows, forLocation: forLocation),
      ),
    );
  }

  // ============================================================
  // RUN BULK IMPORT
  // ============================================================

  Future<_ImportResult> _runBulkImport({
    required List<Map<String, dynamic>> rows,
    required bool forLocation,
    void Function(int completed, int total)? onProgress,
  }) async {
    final api = ref.read(apiServiceProvider);

    try {
      final payload = rows.map((row) {
        return forLocation
            ? _rowToLocationPayload(row)
            : _rowToAssetPayload(row);
      }).toList();

      final response = forLocation
          ? await api.bulkCreateLocations(payload)
          : await api.bulkCreateAssets(payload);

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final successCount = response.data['success_count'] ?? rows.length;

        final failureCount = response.data['failure_count'] ?? 0;

        final errors =
            (response.data['errors'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        onProgress?.call(rows.length, rows.length);

        return _ImportResult(
          successCount: successCount,
          failureCount: failureCount,
          errors: errors,
        );
      }

      return _ImportResult(
        successCount: 0,
        failureCount: rows.length,
        errors: [response.data['message']?.toString() ?? 'Bulk import failed'],
      );
    } catch (e) {
      return _ImportResult(
        successCount: 0,
        failureCount: rows.length,
        errors: ['Bulk import error: $e'],
      );
    }
  }

  // ============================================================
  // LOCATION EXCEL PAYLOAD
  // ============================================================

  Map<String, dynamic> _rowToLocationPayload(Map<String, dynamic> row) {
    return {
      'location_type': row['location_type'],
      'site_name': row['site_name'],
      'building_name': row['building_name'],
      'area_zone': row['area_zone'],
      'floor': row['floor'],
      'room_name': row['room_name'],
      'room_number': row['room_number'],
      'condition': row['condition'],
      'code': row['code'],
      'criticality': row['criticality'],
    };
  }

  // ============================================================
  // RESOLVE LOCATION ID
  // ============================================================

  String? _resolveLocationId(dynamic raw) {
    final v = raw?.toString().trim() ?? '';

    if (v.isEmpty) {
      return null;
    }

    if (int.tryParse(v) != null) {
      return v;
    }

    final locs = _locationOptions['locations'] ?? [];

    for (final m in locs) {
      final label = m['label']?.toString().trim() ?? '';

      final value = m['value']?.toString().trim() ?? '';

      if (label.toLowerCase() == v.toLowerCase() ||
          value.toLowerCase() == v.toLowerCase()) {
        return value;
      }

      if (label.isNotEmpty && label.toLowerCase().contains(v.toLowerCase())) {
        return value;
      }
    }

    return null;
  }

  // ============================================================
  // ASSET EXCEL PAYLOAD
  // ============================================================

  Map<String, dynamic> _rowToAssetPayload(Map<String, dynamic> row) {
    return {
      'location_id': _resolveLocationId(
        row['location_id'] ?? row['location'] ?? row['site_name'],
      ),

      'asset_name': row['asset_name'],

      'asset_code': row['asset_code'],

      'description': row['description'] ?? '',

      'quantity': int.tryParse(row['quantity']?.toString() ?? '') ?? 1,

      'system': row['system'],

      'tag': row['tag'],

      'type': row['type'],

      'group_name': row['group_name'],

      'classification': row['classification'],

      'asset_condition': row['asset_condition'],

      'product_code': row['product_code'],

      'model_type': row['model_type'],

      'manufacturer': row['manufacturer'],

      'purchase_date': row['purchase_date'],

      'warranty_expiry_date': row['warranty_expiry_date'],

      'purchase_cost':
          double.tryParse(row['purchase_cost']?.toString() ?? '') ?? 0.0,

      'supplier': row['supplier'],

      'cost_center': row['cost_center'],

      'comments': row['comments'] ?? '',

      'status': (row['status']?.toString().isNotEmpty ?? false)
          ? row['status']
          : 'ACTIVE',

      'installed_time':
          "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:"
          "${TimeOfDay.now().minute.toString().padLeft(2, '0')} "
          "${TimeOfDay.now().period == DayPeriod.am ? 'AM' : 'PM'}",
    };
  }
}

// ============================================================
// IMPORT RESULT
// ============================================================

class _ImportResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const _ImportResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });
}

// ============================================================
// IMPORT EXCEL BUTTON
// ============================================================

class _ImportExcelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ImportExcelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,

      child: Padding(
        padding: const EdgeInsets.all(6),

        child: SizedBox(
          width: 46,
          height: 46,

          child: Stack(
            clipBehavior: Clip.none,

            alignment: Alignment.center,

            children: [
              const Icon(Icons.table_view, size: 30, color: Color(0xFF217346)),

              Positioned(
                right: -2,
                bottom: -2,

                child: Container(
                  padding: const EdgeInsets.all(2),

                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.upload,
                    size: 14,
                    color: Color(0xFF107C41),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// IMPORT PREVIEW SHEET
// ============================================================

class _ExcelImportPreviewSheet extends StatefulWidget {
  final bool forLocation;
  final String fileName;
  final List<Map<String, dynamic>> rows;

  final List<String> unrecognizedHeaders;

  final Future<_ImportResult> Function(List<Map<String, dynamic>> rows)
  onConfirmImport;

  const _ExcelImportPreviewSheet({
    required this.forLocation,
    required this.fileName,
    required this.rows,
    required this.unrecognizedHeaders,
    required this.onConfirmImport,
  });

  @override
  State<_ExcelImportPreviewSheet> createState() =>
      _ExcelImportPreviewSheetState();
}

class _ExcelImportPreviewSheetState extends State<_ExcelImportPreviewSheet> {
  bool _importing = false;

  int _completed = 0;

  _ImportResult? _result;

  Future<void> _confirmImport() async {
    setState(() {
      _importing = true;
      _completed = 0;
    });

    final _ImportResult result = await widget.onConfirmImport(widget.rows);

    if (!mounted) return;

    setState(() {
      _importing = false;
      _completed = widget.rows.length;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewRows = widget.rows.take(8).toList();

    final previewColumns = previewRows.isEmpty
        ? <String>[]
        : previewRows.first.keys.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  children: [
                    const Icon(
                      Icons.table_view,
                      color: Color(0xFF217346),
                      size: 22,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        _result != null
                            ? 'Import Complete'
                            : 'Import ${widget.forLocation ? 'Locations' : 'Assets'}',

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),

                      onPressed: _importing
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    widget.fileName,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _result != null
                    ? _buildResultView(_result!)
                    : _importing
                    ? _buildProgressView()
                    : _buildPreviewView(
                        scrollController,
                        previewColumns,
                        previewRows,
                      ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),

                child: _result != null
                    ? SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          child: const Text(
                            'Done',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _importing
                                  ? null
                                  : () => Navigator.of(context).pop(),

                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white30),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),

                              child: const Text('Cancel'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: _importing ? null : _confirmImport,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),

                              child: Text(
                                'Import ${widget.rows.length} row${widget.rows.length == 1 ? '' : 's'}',

                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PREVIEW VIEW
  // ============================================================

  Widget _buildPreviewView(
    ScrollController scrollController,
    List<String> columns,
    List<Map<String, dynamic>> previewRows,
  ) {
    return SingleChildScrollView(
      controller: scrollController,

      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            '${widget.rows.length} row${widget.rows.length == 1 ? '' : 's'} found'
            '${widget.rows.length > previewRows.length ? ' (showing first ${previewRows.length})' : ''}',

            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),

          if (widget.unrecognizedHeaders.isNotEmpty) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.amber.shade300,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'Unrecognized column(s), ignored: ${widget.unrecognizedHeaders.join(', ')}',

                      style: TextStyle(
                        color: Colors.amber.shade200,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF202A32)),

              columns: columns
                  .map(
                    (c) => DataColumn(
                      label: Text(
                        c,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),

              rows: previewRows
                  .map(
                    (row) => DataRow(
                      cells: columns
                          .map(
                            (c) => DataCell(
                              Text(
                                row[c]?.toString() ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS VIEW
  // ============================================================

  Widget _buildProgressView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const CircularProgressIndicator(color: AppColors.primary),

            const SizedBox(height: 16),

            Text(
              'Importing $_completed of ${widget.rows.length}...',

              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESULT VIEW
  // ============================================================

  Widget _buildResultView(_ImportResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                result.failureCount == 0
                    ? Icons.check_circle
                    : Icons.error_outline,

                color: result.failureCount == 0 ? Colors.green : Colors.amber,

                size: 22,
              ),

              const SizedBox(width: 10),

              Text(
                '${result.successCount} imported, ${result.failureCount} failed',

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 14),

            const Text(
              'Errors',

              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            ...result.errors.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),

                child: Text(
                  e,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
