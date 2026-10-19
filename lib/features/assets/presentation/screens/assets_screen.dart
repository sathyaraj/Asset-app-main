import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assets_app/core/utils/app_colors.dart';
import 'package:assets_app/core/utils/api_service.dart';
import 'package:assets_app/core/utils/page_permission.dart';
import 'package:assets_app/features/assets/presentation/screens/create_new_screen.dart';

class Asset {
  final int id;
  final String name;
  final String code;
  final String location;
  final String locationDisplay;
  final String status;
  final String createdDate;
  final String installedTime;
  final String lastUpdated;

  final String description;
  final int quantity;
  final String system;
  final String tag;
  final String type;
  final String groupName;
  final String classification;
  final String condition;
  final String productCode;
  final String modelType;
  final String manufacturer;
  final String purchaseDate;
  final String warrantyExpiryDate;
  final double purchaseCost;
  final String supplier;
  final String costCenter;
  final String comments;

  Asset({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.locationDisplay,
    required this.status,
    required this.createdDate,
    required this.installedTime,
    required this.lastUpdated,
    this.description = '',
    this.quantity = 1,
    this.system = '',
    this.tag = '',
    this.type = '',
    this.groupName = '',
    this.classification = '',
    this.condition = '',
    this.productCode = '',
    this.modelType = '',
    this.manufacturer = '',
    this.purchaseDate = '',
    this.warrantyExpiryDate = '',
    this.purchaseCost = 0.0,
    this.supplier = '',
    this.costCenter = '',
    this.comments = '',
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: int.parse(json['id'].toString()),
      name: json['asset_name'] ?? '',
      code: json['asset_code'] ?? '',
      location: json['location_id']?.toString() ?? '',
      locationDisplay: json['location_display'] ?? 'No Location',
      status: json['status'] ?? 'ACTIVE',
      createdDate: json['created_at'] != null
          ? _formatDate(json['created_at'])
          : '',
      installedTime: json['installed_time'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
      description: json['description'] ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      system: json['system'] ?? '',
      tag: json['tag'] ?? '',
      type: json['type'] ?? '',
      groupName: json['group_name'] ?? '',
      classification: json['classification'] ?? '',
      condition: json['asset_condition'] ?? '',
      productCode: json['product_code'] ?? '',
      modelType: json['model_type'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      warrantyExpiryDate: json['warranty_expiry_date'] ?? '',
      purchaseCost:
          double.tryParse(json['purchase_cost']?.toString() ?? '0') ?? 0.0,
      supplier: json['supplier'] ?? '',
      costCenter: json['cost_center'] ?? '',
      comments: json['comments'] ?? '',
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  List<Asset> _assets = [];

  bool _isLoading = true;

  String _totalAssets = '0';
  String _inMaintenance = '0';

  Timer? _refreshTimer;

  String? _errorMessage;

  String _searchQuery = '';

  int? _expandedIndex;

  // ============================================================
  // PAGE PERMISSION
  // ============================================================

  PagePermission? _assetPermission;

  bool _permissionLoading = true;

  // IMPORTANT:
  // This is the page_key from your pages table.
  // No page_id is hardcoded.
  static const String _assetPageKey = 'assets';

  bool get _canView => _assetPermission?.canView == true;

  bool get _canCreate => _assetPermission?.canCreate == true;

  bool get _canUpdate => _assetPermission?.canUpdate == true;

  bool get _canDelete => _assetPermission?.canDelete == true;

  @override
  void initState() {
    super.initState();

    // First load permission.
    // Assets will be loaded only when canView = true.
    _loadAssetPermission();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;

      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      // Refresh only if user has view permission.
      if (!_canView) {
        return;
      }

      _fetchAssets(isSilent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // LOAD ASSET PAGE PERMISSION
  // ============================================================

  Future<void> _loadAssetPermission() async {
    try {
      final pages = await ref.read(apiServiceProvider).getMyPages();

      PagePermission? assetPermission;

      for (final page in pages) {
        final pageKey = page.pageKey.trim().toLowerCase();

        if (pageKey == _assetPageKey.toLowerCase()) {
          assetPermission = page;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _assetPermission = assetPermission;
        _permissionLoading = false;
      });

      // ========================================================
      // LOAD ASSETS ONLY IF VIEW PERMISSION EXISTS
      // ========================================================

      if (assetPermission?.canView == true) {
        await _fetchAssets();
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _permissionLoading = false;
        _assetPermission = null;
        _isLoading = false;
        _errorMessage = 'Unable to load page permission.';
      });
    }
  }

  // ============================================================
  // EXPORT OPTIONS
  // ============================================================

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Export Assets',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Export All',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Export all assets',
                  style: TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);

                  _exportAssetsToExcel(_assets, 'All_Assets');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.filter_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Export Current Results',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Export currently filtered assets',
                  style: TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);

                  final filteredAssets = _assets.where((asset) {
                    final q = _searchQuery.toLowerCase();

                    return asset.name.toLowerCase().contains(q) ||
                        asset.code.toLowerCase().contains(q) ||
                        asset.locationDisplay.toLowerCase().contains(q);
                  }).toList();

                  _exportAssetsToExcel(filteredAssets, 'Filtered_Assets');
                },
              ),
            ],
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
          ],
        );
      },
    );
  }

  // ============================================================
  // NORMALIZE EXCEL DATE
  // ============================================================

  String normalizeExcelDate(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    final text = value.trim();

    // YYYY-MM-DD
    final isoRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (isoRegex.hasMatch(text)) {
      return text;
    }

    // DD/MM/YYYY
    final slashParts = text.split('/');

    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);

      if (day != null && month != null && year != null) {
        return '${year.toString().padLeft(4, '0')}-'
            '${month.toString().padLeft(2, '0')}-'
            '${day.toString().padLeft(2, '0')}';
      }
    }

    // DD-MM-YYYY
    final dashParts = text.split('-');

    if (dashParts.length == 3) {
      final day = int.tryParse(dashParts[0]);
      final month = int.tryParse(dashParts[1]);
      final year = int.tryParse(dashParts[2]);

      if (day != null && month != null && year != null && year > 31) {
        return '${year.toString().padLeft(4, '0')}-'
            '${month.toString().padLeft(2, '0')}-'
            '${day.toString().padLeft(2, '0')}';
      }
    }

    return '';
  }

  // ============================================================
  // IMPORT EXCEL
  // ============================================================

  Future<void> _importAssetsFromExcel() async {
    // ==========================================================
    // CREATE PERMISSION
    // ==========================================================

    if (!_canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to import assets.'),
        ),
      );

      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final bytes = result.files.single.bytes;

      if (bytes == null) {
        throw Exception('Unable to read Excel file.');
      }

      print('========== EXCEL FILE ==========');
      print('FILE NAME: ${result.files.single.name}');
      print('FILE SIZE: ${bytes.length}');

      final excelFile = excel.Excel.decodeBytes(bytes);

      if (excelFile.tables.isEmpty) {
        throw Exception('No Excel sheet found.');
      }

      final sheet = excelFile.tables.values.first;

      print('========== EXCEL SHEET ==========');
      print('SHEETS: ${excelFile.tables.keys}');
      print('SHEET NAME: ${sheet.sheetName}');
      print('MAX ROWS: ${sheet.maxRows}');
      print('MAX COLUMNS: ${sheet.maxColumns}');

      if (sheet.maxRows < 2) {
        throw Exception('Excel file does not contain asset data.');
      }

      // ==========================================================
      // HEADERS
      // ==========================================================

      final headers = sheet.rows.first.map((cell) {
        return cell?.value?.toString().trim() ?? '';
      }).toList();

      print('HEADERS: $headers');

      // ==========================================================
      // ASSETS
      // ==========================================================

      final List<Map<String, dynamic>> assets = [];

      for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        final row = sheet.rows[rowIndex];

        // Skip empty rows
        if (row.every((cell) => cell?.value == null)) {
          continue;
        }

        // ========================================================
        // GET VALUE
        // ========================================================

        String getValue(String columnName) {
          final columnAliases = <String, List<String>>{
            'Asset Name': ['Asset Name', 'asset_name'],
            'Asset Code': ['Asset Code', 'asset_code'],
            'Location ID': ['Location ID', 'location_id'],
            'Location': ['Location', 'location'],
            'Description': ['Description', 'description'],
            'Quantity': ['Quantity', 'quantity'],
            'System': ['System', 'system'],
            'Tag': ['Tag', 'tag'],
            'Type': ['Type', 'type'],
            'Group': ['Group', 'group_name'],
            'Classification': ['Classification', 'classification'],
            'Condition': ['Condition', 'asset_condition'],
            'Product Code': ['Product Code', 'product_code'],
            'Model Type': ['Model Type', 'model_type'],
            'Manufacturer': ['Manufacturer', 'manufacturer'],
            'Purchase Date': ['Purchase Date', 'purchase_date'],
            'Warranty Expiry Date': [
              'Warranty Expiry Date',
              'warranty_expiry_date',
            ],
            'Purchase Cost': ['Purchase Cost', 'purchase_cost'],
            'Supplier': ['Supplier', 'supplier'],
            'Cost Center': ['Cost Center', 'cost_center'],
            'Comments': ['Comments', 'comments'],
            'Status': ['Status', 'status'],
            'Installed Time': ['Installed Time', 'installed_time'],
          };

          final aliases = columnAliases[columnName] ?? [columnName];

          final index = headers.indexWhere((header) {
            final normalizedHeader = header.trim().toLowerCase();

            return aliases.any(
              (alias) => normalizedHeader == alias.trim().toLowerCase(),
            );
          });

          if (index == -1 || index >= row.length) {
            return '';
          }

          return row[index]?.value?.toString().trim() ?? '';
        }

        // ========================================================
        // REQUIRED FIELDS
        // ========================================================

        final assetName = getValue('Asset Name');

        final assetCode = getValue('Asset Code');

        print('========== EXCEL ROW ==========');
        print('ROW: $rowIndex');
        print('ASSET NAME: $assetName');
        print('ASSET CODE: $assetCode');

        if (assetName.isEmpty || assetCode.isEmpty) {
          print('SKIPPED ROW: $rowIndex');
          print('Reason: Asset Name or Asset Code is empty.');
          continue;
        }

        // ========================================================
        // LOCATION
        // ========================================================

        final locationIdText = getValue('Location ID').isNotEmpty
            ? getValue('Location ID')
            : getValue('Location');

        // ========================================================
        // STATUS
        // ========================================================

        String status = getValue('Status');

        if (status.isEmpty) {
          status = 'ACTIVE';
        }

        status = status.toUpperCase();

        if (!['ACTIVE', 'MAINTENANCE', 'STORED'].contains(status)) {
          print(
            'Invalid status "$status" at row $rowIndex. '
            'Defaulting to ACTIVE.',
          );

          status = 'ACTIVE';
        }

        // ========================================================
        // QUANTITY
        // ========================================================

        final quantityText = getValue('Quantity');

        final quantity = int.tryParse(quantityText) ?? 1;

        // ========================================================
        // PURCHASE COST
        // ========================================================

        final purchaseCostText = getValue('Purchase Cost');

        final purchaseCost =
            double.tryParse(purchaseCostText.replaceAll(',', '').trim()) ?? 0;

        // ========================================================
        // ADD ASSET
        // ========================================================

        assets.add({
          'asset_name': assetName,
          'asset_code': assetCode,

          'location_id': int.tryParse(locationIdText),

          'status': status,

          'description': getValue('Description'),

          'quantity': quantity,

          'system': getValue('System'),

          'tag': getValue('Tag'),

          'type': getValue('Type'),

          'group_name': getValue('Group'),

          'classification': getValue('Classification'),

          'asset_condition': getValue('Condition'),

          'product_code': getValue('Product Code'),

          'model_type': getValue('Model Type'),

          'manufacturer': getValue('Manufacturer'),

          'purchase_date': normalizeExcelDate(getValue('Purchase Date')),

          'warranty_expiry_date': normalizeExcelDate(
            getValue('Warranty Expiry Date'),
          ),

          'purchase_cost': purchaseCost,

          'supplier': getValue('Supplier'),

          'cost_center': getValue('Cost Center'),

          'comments': getValue('Comments'),

          'installed_time': getValue('Installed Time').isEmpty
              ? '09:00 AM'
              : getValue('Installed Time'),
        });

        print('ASSET ADDED: $assetCode');
      }

      // ==========================================================
      // CHECK ASSET DATA
      // ==========================================================

      if (assets.isEmpty) {
        throw Exception('No valid asset records found in Excel.');
      }

      print('========== EXCEL IMPORT ==========');
      print('TOTAL ASSETS: ${assets.length}');
      print('ASSETS DATA: $assets');

      // ==========================================================
      // BULK CREATE
      // ==========================================================

      print('========== CALLING BULK CREATE API ==========');

      final response = await ref
          .read(apiServiceProvider)
          .bulkCreateAssets(assets);

      print('========== BULK CREATE RESPONSE ==========');
      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE DATA: ${response.data}');

      if (!mounted) return;

      await _fetchAssets();

      final responseData = response.data;

      final successCount =
          responseData is Map && responseData['success_count'] != null
          ? responseData['success_count'].toString()
          : assets.length.toString();

      final failureCount =
          responseData is Map && responseData['failure_count'] != null
          ? responseData['failure_count'].toString()
          : '0';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import completed. '
            'Success: $successCount, '
            'Failed: $failureCount',
          ),
        ),
      );
    } catch (e) {
      print('========== EXCEL IMPORT ERROR ==========');
      print(e);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel import failed: $e')));
    }
  }

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  Future<void> _exportAssetsToExcel(List<Asset> assets, String fileName) async {
    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assets available to export.')),
      );

      return;
    }

    try {
      final excelFile = excel.Excel.createExcel();

      final sheet = excelFile['Assets'];

      final headers = [
        'ID',
        'Asset Name',
        'Asset Code',
        'Location ID',
        'Location',
        'Status',
        'Created Date',
        'Installed Time',
        'Last Updated',
        'Description',
        'Quantity',
        'System',
        'Tag',
        'Type',
        'Group',
        'Classification',
        'Condition',
        'Product Code',
        'Model Type',
        'Manufacturer',
        'Purchase Date',
        'Warranty Expiry Date',
        'Purchase Cost',
        'Supplier',
        'Cost Center',
        'Comments',
      ];

      sheet.appendRow(
        headers.map((header) => excel.TextCellValue(header)).toList(),
      );

      for (final asset in assets) {
        sheet.appendRow([
          excel.IntCellValue(asset.id),
          excel.TextCellValue(asset.name),
          excel.TextCellValue(asset.code),
          excel.TextCellValue(asset.location),
          excel.TextCellValue(asset.locationDisplay),
          excel.TextCellValue(asset.status),
          excel.TextCellValue(asset.createdDate),
          excel.TextCellValue(asset.installedTime),
          excel.TextCellValue(asset.lastUpdated),
          excel.TextCellValue(asset.description),
          excel.IntCellValue(asset.quantity),
          excel.TextCellValue(asset.system),
          excel.TextCellValue(asset.tag),
          excel.TextCellValue(asset.type),
          excel.TextCellValue(asset.groupName),
          excel.TextCellValue(asset.classification),
          excel.TextCellValue(asset.condition),
          excel.TextCellValue(asset.productCode),
          excel.TextCellValue(asset.modelType),
          excel.TextCellValue(asset.manufacturer),
          excel.TextCellValue(asset.purchaseDate),
          excel.TextCellValue(asset.warrantyExpiryDate),
          excel.DoubleCellValue(asset.purchaseCost),
          excel.TextCellValue(asset.supplier),
          excel.TextCellValue(asset.costCenter),
          excel.TextCellValue(asset.comments),
        ]);
      }

      final bytes = excelFile.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Excel file.');
      }

      final directory = await getTemporaryDirectory();

      final file = File('${directory.path}/$fileName.xlsx');

      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: '$fileName.xlsx',
        text: 'Asset Inventory Excel Report',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel export failed: $e')));
    }
  }

  // ============================================================
  // FETCH ASSETS
  // ============================================================

  Future<void> _fetchAssets({bool isSilent = false}) async {
    // ==========================================================
    // VIEW PERMISSION
    // ==========================================================

    if (!_canView) {
      return;
    }

    if (!isSilent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final apiService = ref.read(apiServiceProvider);

      final response = await apiService.getAssets();

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data'];

        final stats = response.data['stats'];

        if (mounted) {
          setState(() {
            _assets = data.map((e) => Asset.fromJson(e)).toList();

            _totalAssets = stats['total_assets'].toString();

            _inMaintenance = stats['in_maintenance'].toString();

            _isLoading = false;

            _errorMessage = null;
          });
        }
      } else {
        if (mounted && !isSilent) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Unable to load assets.';
          });
        }
      }
    } catch (e) {
      if (mounted && !isSilent) {
        setState(() {
          _isLoading = false;

          _errorMessage = 'Connection error. Retrying...';
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // PERMISSION LOADING
    // ==========================================================

    if (_permissionLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Asset Inventory',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // ==========================================================
    // NO VIEW PERMISSION
    // ==========================================================

    if (!_canView) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'Asset Inventory',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to view Asset Inventory.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredAssets = _assets.where((asset) {
      final q = _searchQuery.toLowerCase();

      return asset.name.toLowerCase().contains(q) ||
          asset.code.toLowerCase().contains(q) ||
          asset.locationDisplay.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        title: Text(
          'Asset Inventory',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        actions: [
          // ======================================================
          // IMPORT EXCEL
          // CAN CREATE
          // ======================================================
          if (_canCreate)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _importAssetsFromExcel,

                icon: const Icon(Icons.upload_file, size: 16),

                label: const Text('Import Excel'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          // ======================================================
          // EXPORT EXCEL
          // NO PERMISSION REQUIRED
          // ======================================================
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _showExportOptions,

              icon: const Icon(Icons.download, size: 16),

              label: const Text('Export Excel'),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),

                elevation: 4,

                shadowColor: AppColors.primary.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          _buildSearchBar(),

          _buildStatsRow(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredAssets.isEmpty
                ? Center(
                    child: Text(
                      _errorMessage ?? 'No assets found',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),

                    itemCount: filteredAssets.length,

                    itemBuilder: (context, index) {
                      return _buildAssetCard(filteredAssets[index], index);
                    },
                  ),
          ),
        ],
      ),

      // ==========================================================
      // ADD ASSET
      // CAN CREATE
      // ==========================================================
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateNewScreen(),
                  ),
                ).then((_) {
                  if (_canView) {
                    _fetchAssets();
                  }
                });
              },

              backgroundColor: AppColors.primary,

              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          hintText: 'Search by name or code...',

          hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary),

          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),

          suffixIcon: Container(
            margin: const EdgeInsets.all(10),

            padding: const EdgeInsets.all(4),

            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.5),
              ),

              borderRadius: BorderRadius.circular(4),
            ),

            child: const Text(
              '/',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ),

          filled: true,

          fillColor: AppColors.cardBackground,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: Row(
        children: [
          _buildStatSummary('TOTAL ASSETS', _totalAssets, null),

          const SizedBox(width: 12),

          _buildStatSummary(
            'IN MAINTENANCE',
            _inMaintenance,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatSummary(String label, String value, Color? valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: AppColors.cardBackground,

          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              label,

              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,

                fontSize: 10,

                fontWeight: FontWeight.bold,

                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              value,

              style: GoogleFonts.outfit(
                color: valueColor ?? AppColors.textPrimary,

                fontSize: 24,

                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ASSET CARD
  // ============================================================

  Widget _buildAssetCard(Asset asset, int index) {
    final isExpanded = _expandedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),

      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),

      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },

        borderRadius: BorderRadius.circular(16),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          asset.name,

                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,

                            fontSize: 18,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          asset.code,

                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,

                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildStatusBadge(asset.status),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 16,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      asset.locationDisplay,

                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,

                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Created: ${asset.createdDate}',

                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,

                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              if (isExpanded) ...[
                const SizedBox(height: 16),

                const Divider(color: Colors.white10),

                const SizedBox(height: 16),

                _buildExpandRow('Installed Time', asset.installedTime),

                _buildExpandRow('Last Updated', asset.lastUpdated),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,

                  children: [
                    // =========================================
                    // EDIT
                    // CAN UPDATE
                    // =========================================
                    if (_canUpdate)
                      TextButton.icon(
                        onPressed: () {
                          _showEditAssetDialog(asset);
                        },

                        icon: const Icon(Icons.edit, size: 16),

                        label: const Text('Edit'),

                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),

                    if (_canUpdate && _canDelete) const SizedBox(width: 8),

                    // =========================================
                    // DELETE
                    // CAN DELETE
                    // =========================================
                    if (_canDelete)
                      TextButton.icon(
                        onPressed: () {
                          _deleteAsset(asset.id);
                        },

                        icon: const Icon(Icons.delete, size: 16),

                        label: const Text('Delete'),

                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD ASSET DIALOG
  // ============================================================

  void _showAddAssetDialog() {
    if (!_canCreate) {
      return;
    }

    _showAssetDialog();
  }

  // ============================================================
  // EDIT ASSET DIALOG
  // ============================================================

  void _showEditAssetDialog(Asset asset) {
    if (!_canUpdate) {
      return;
    }

    _showAssetDialog(asset: asset);
  }

  // ============================================================
  // ASSET DIALOG
  // ============================================================

  Future<void> _showAssetDialog({Asset? asset}) async {
    // ==========================================================
    // PERMISSION CHECK
    // ==========================================================

    if (asset == null && !_canCreate) {
      return;
    }

    if (asset != null && !_canUpdate) {
      return;
    }

    final nameController = TextEditingController(text: asset?.name);

    final codeController = TextEditingController(text: asset?.code);

    String status = asset?.status ?? 'ACTIVE';

    String? selectedLocationId =
        (asset?.location != null && asset!.location.isNotEmpty)
        ? asset.location
        : null;

    // ==========================================================
    // LOCATION OPTIONS
    // ==========================================================

    List<Map<String, String>> locationOptions = [];

    bool isLoadingLocations = true;

    String? locationLoadError;

    try {
      final resp = await ref.read(apiServiceProvider).getAssetDropdowns();

      if (resp.statusCode == 200 && resp.data['status'] == 'success') {
        final dynamic raw = resp.data['data'];

        if (raw is Map && raw['locations'] is List) {
          for (final item in raw['locations']) {
            if (item is Map) {
              locationOptions.add({
                'label': item['label']?.toString() ?? '',
                'value': item['value']?.toString() ?? '',
              });
            }
          }
        }
      } else {
        locationLoadError = 'Failed to load locations';
      }
    } catch (e) {
      locationLoadError = e.toString();
    }

    isLoadingLocations = false;

    // ==========================================================
    // ORPHAN LOCATION
    // ==========================================================

    if (selectedLocationId != null &&
        selectedLocationId.isNotEmpty &&
        !locationOptions.any((e) => e['value'] == selectedLocationId)) {
      locationOptions.insert(0, {
        'label': asset?.locationDisplay ?? 'Location #$selectedLocationId',
        'value': selectedLocationId,
      });
    }

    if (!mounted) return;

    // ==========================================================
    // DIALOG
    // ==========================================================

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,

          title: Text(
            asset == null ? 'Add New Asset' : 'Edit Asset',

            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                _buildDialogField('Asset Name', nameController),

                _buildDialogField(
                  'Asset Code',
                  codeController,
                  enabled: asset == null,
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Location',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                if (isLoadingLocations)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (locationLoadError != null)
                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Text(
                      'Could not load locations: $locationLoadError',

                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value:
                        locationOptions.any(
                          (e) => e['value'].toString() == selectedLocationId,
                        )
                        ? selectedLocationId
                        : null,

                    isExpanded: true,

                    dropdownColor: AppColors.cardBackground,

                    style: const TextStyle(color: Colors.white),

                    decoration: InputDecoration(
                      hintText: 'Select Location',

                      hintStyle: const TextStyle(color: Colors.grey),

                      filled: true,

                      fillColor: Colors.white.withOpacity(0.05),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),

                        borderSide: BorderSide.none,
                      ),
                    ),

                    items: locationOptions.map((e) {
                      final value = e['value']?.toString() ?? '';

                      final label = e['label']?.toString() ?? '';

                      return DropdownMenuItem<String>(
                        value: value,

                        child: Text(
                          label,

                          style: const TextStyle(color: Colors.white),

                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setDialogState(() {
                        selectedLocationId = value;
                      });
                    },
                  ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: status,

                  dropdownColor: AppColors.cardBackground,

                  style: const TextStyle(color: Colors.white),

                  decoration: InputDecoration(
                    labelText: 'Status',

                    labelStyle: const TextStyle(color: AppColors.textSecondary),

                    filled: true,

                    fillColor: Colors.white.withOpacity(0.05),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: BorderSide.none,
                    ),
                  ),

                  items: ['ACTIVE', 'MAINTENANCE', 'STORED']
                      .map(
                        (e) =>
                            DropdownMenuItem<String>(value: e, child: Text(e)),
                      )
                      .toList(),

                  onChanged: (val) {
                    setDialogState(() {
                      status = val!;
                    });
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                // ==============================================
                // FINAL PERMISSION CHECK
                // ==============================================

                if (asset == null && !_canCreate) {
                  return;
                }

                if (asset != null && !_canUpdate) {
                  return;
                }

                final data = {
                  if (asset != null) 'id': asset.id,

                  'asset_name': nameController.text.trim(),

                  'asset_code': codeController.text.trim(),

                  'location_id':
                      selectedLocationId == null || selectedLocationId!.isEmpty
                      ? null
                      : int.tryParse(selectedLocationId!),

                  'status': status,

                  'installed_time': asset?.installedTime ?? '09:00 AM',
                };

                final api = ref.read(apiServiceProvider);

                try {
                  if (asset == null) {
                    await api.createAsset(data);
                  } else {
                    await api.updateAsset(data);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                  }

                  _fetchAssets();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),

              child: Text(
                asset == null ? 'Add Asset' : 'Save Changes',

                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG FIELD
  // ============================================================

  Widget _buildDialogField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: TextField(
        controller: controller,

        enabled: enabled,

        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          labelText: label,

          labelStyle: const TextStyle(color: AppColors.textSecondary),

          filled: true,

          fillColor: Colors.white.withOpacity(0.05),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),

            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELETE ASSET
  // ============================================================

  Future<void> _deleteAsset(int id) async {
    // ==========================================================
    // DELETE PERMISSION
    // ==========================================================

    if (!_canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to delete assets.'),
        ),
      );

      return;
    }

    final confirm = await showDialog<bool>(
      context: context,

      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        title: const Text(
          'Confirm Delete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        content: const Text(
          'Are you sure you want to permanently delete this asset?',

          style: TextStyle(color: Colors.white70),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },

            child: const Text(
              'Cancel',

              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },

            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),

            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiServiceProvider).deleteAsset(id);

        _fetchAssets();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset deleted successfully')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  // ============================================================
  // EXPAND ROW
  // ============================================================

  Widget _buildExpandRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            label,

            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,

              fontSize: 13,
            ),
          ),

          Text(
            value,

            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,

              fontSize: 13,

              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;

    switch (status) {
      case 'ACTIVE':
        bg = AppColors.activeGreen;
        text = AppColors.activeGreenText;
        break;

      case 'MAINTENANCE':
        bg = AppColors.maintenanceOrange;
        text = AppColors.maintenanceOrangeText;
        break;

      default:
        bg = AppColors.storedGrey;
        text = AppColors.storedGreyText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

      decoration: BoxDecoration(
        color: bg,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Text(
        status,

        style: GoogleFonts.outfit(
          color: text,

          fontSize: 10,

          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
