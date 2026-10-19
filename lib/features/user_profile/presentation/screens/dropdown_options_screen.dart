import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assets_app/core/utils/api_service.dart';
import '../theme/app_colors.dart';

class DropdownOptionsScreen extends ConsumerStatefulWidget {
  const DropdownOptionsScreen({super.key});

  @override
  ConsumerState<DropdownOptionsScreen> createState() =>
      _DropdownOptionsScreenState();
}

class _DropdownOptionsScreenState extends ConsumerState<DropdownOptionsScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  // ============================================================
  // FILTER
  // ============================================================

  String _selectedCategory = 'All';

  // ============================================================
  // PAGINATION
  // ============================================================

  int _currentPage = 1;
  int _totalPages = 1;

  final int _limit = 10;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  List<Map<String, dynamic>> _options = [];

  List<String> _categories = ['All'];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptions();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD OPTIONS
  // ============================================================
  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final api = ref.read(apiServiceProvider);

      final Map<String, dynamic> response = await api.getDropdownOptions(
        search: _searchController.text.trim(),
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        page: _currentPage,
        limit: _limit,
      );

      if (response['success'] == true) {
        final data = response['data'];

        setState(() {
          _options = data is List
              ? List<Map<String, dynamic>>.from(
                  data.map((item) => Map<String, dynamic>.from(item)),
                )
              : [];

          // Support nested pagination response
          final pagination = response['pagination'];

          if (pagination is Map) {
            _totalPages =
                int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;
          } else {
            // Support old/top-level response
            _totalPages =
                int.tryParse(response['total_pages']?.toString() ?? '1') ?? 1;
          }

          // Categories
          final categories = response['categories'];

          if (categories is List) {
            _categories = ['All', ...categories.map((e) => e.toString())];
          }
        });
      } else {
        throw Exception(
          response['message']?.toString() ?? 'Failed to load dropdown options',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dropdown options: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CLEAN ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _search() {
    setState(() {
      _currentPage = 1;
    });

    _loadOptions();
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _currentPage = 1;
    });

    _loadOptions();
  }

  // ============================================================
  // CATEGORY CHANGE
  // ============================================================

  void _changeCategory(String? value) {
    if (value == null) return;

    setState(() {
      _selectedCategory = value;
      _currentPage = 1;
    });

    _loadOptions();
  }

  // ============================================================
  // PAGE CHANGE
  // ============================================================

  void _changePage(int page) {
    if (page < 1 || page > _totalPages) {
      return;
    }

    if (page == _currentPage) {
      return;
    }

    setState(() {
      _currentPage = page;
    });

    _loadOptions();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteOption(Map<String, dynamic> option) async {
    final dynamic idValue = option['id'];

    final int? id = int.tryParse(idValue?.toString() ?? '');

    if (id == null || id <= 0) {
      _showMessage('Invalid dropdown option ID.', isError: true);

      return;
    }

    final String label = option['label']?.toString() ?? '';

    final confirmed = await _showDeleteConfirmation(label);

    if (confirmed != true) {
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);

      await api.deleteDropdownOption(id);

      if (!mounted) return;

      _showMessage('Dropdown option deleted successfully.');

      // ========================================================
      // IF LAST ITEM OF PAGE DELETED
      // ========================================================

      if (_options.length == 1 && _currentPage > 1) {
        _currentPage--;
      }

      await _loadOptions();
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanErrorMessage(e), isError: true);
    }
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<bool?> _showDeleteConfirmation(String label) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Option'),
          content: Text('Are you sure you want to delete "$label"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ADD / EDIT DIALOG
  // ============================================================

  void _showAddEditDialog({Map<String, dynamic>? option}) {
    final bool isEdit = option != null;

    final categoryController = TextEditingController(
      text: option?['category']?.toString() ?? '',
    );

    final labelController = TextEditingController(
      text: option?['label']?.toString() ?? '',
    );

    final valueController = TextEditingController(
      text: option?['value']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final api = ref.read(apiServiceProvider);

                final data = {
                  'category': categoryController.text.trim(),
                  'label': labelController.text.trim(),
                  'value': valueController.text.trim(),
                };

                // ==================================================
                // CREATE
                // ==================================================

                if (!isEdit) {
                  await api.createDropdownOption(data);
                }
                // ==================================================
                // UPDATE
                // ==================================================
                else {
                  final dynamic idValue = option!['id'];

                  final int? id = int.tryParse(idValue?.toString() ?? '');

                  if (id == null || id <= 0) {
                    throw Exception('Invalid dropdown option ID.');
                  }

                  await api.updateDropdownOption(option['id'], {
                    'category': categoryController.text.trim(),
                    'label': labelController.text.trim(),
                    'value': valueController.text.trim(),
                  });
                }

                if (!mounted) return;

                Navigator.pop(dialogContext);

                _showMessage(
                  isEdit
                      ? 'Dropdown option updated successfully.'
                      : 'Dropdown option created successfully.',
                );

                // ==================================================
                // AFTER SAVE
                // ==================================================

                await _loadOptions();
              } catch (e) {
                setDialogState(() {
                  saving = false;
                });

                if (!mounted) return;

                _showMessage(_cleanErrorMessage(e), isError: true);
              }
            }

            return AlertDialog(
              title: Text(
                isEdit ? 'Edit Dropdown Option' : 'Add Dropdown Option',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),

              content: SizedBox(
                width: 450,

                child: Form(
                  key: formKey,

                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        // ==========================================
                        // CATEGORY
                        // ==========================================
                        _buildDialogField(
                          controller: categoryController,
                          label: 'Category',
                          hint: 'Example: location_type',
                          icon: Icons.category_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter category';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==========================================
                        // LABEL
                        // ==========================================
                        _buildDialogField(
                          controller: labelController,
                          label: 'Label',
                          hint: 'Example: Warehouse',
                          icon: Icons.label_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter label';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==========================================
                        // VALUE
                        // ==========================================
                        _buildDialogField(
                          controller: valueController,
                          label: 'Value',
                          hint: 'Example: Warehouse',
                          icon: Icons.data_object,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter value';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: saving ? null : save,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DIALOG FIELD
  // ============================================================

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,

      textInputAction: TextInputAction.next,

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(icon, color: AppColors.textSecondary),

        filled: true,

        fillColor: AppColors.background,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),

        backgroundColor: isError ? Colors.red : Colors.green,

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(16),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(child: _buildContent()),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditDialog();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 12, 24, 12),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        // ======================================================
        // BACK ARROW
        // ======================================================
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

        // ======================================================
        // HEADER ICON
        // ======================================================
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppColors.primary,
            size: 25,
          ),
        ),

        const SizedBox(width: 14),

        // ======================================================
        // TITLE
        // ======================================================
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dropdown Options',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage application dropdown values',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // REFRESH
        // ======================================================
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _loadOptions,
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(34),

      child: Column(
        children: [
          _buildFilterSection(),

          const SizedBox(height: 20),

          Expanded(child: _buildTableCard()),

          const SizedBox(height: 12),

          _buildPagination(),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER SECTION
  // ============================================================

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.cardWhite,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          // ======================================================
          // SEARCH
          // ======================================================
          Expanded(
            flex: 3,

            child: TextField(
              controller: _searchController,

              onChanged: (_) {
                setState(() {});
              },

              onSubmitted: (_) {
                _search();
              },

              decoration: InputDecoration(
                hintText: 'Search category, label, value...',

                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),

                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,

                filled: true,

                fillColor: AppColors.background,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ======================================================
          // CATEGORY
          // ======================================================
          SizedBox(
            width: 220,

            child: DropdownButtonFormField<String>(
              value: _categories.contains(_selectedCategory)
                  ? _selectedCategory
                  : 'All',

              decoration: InputDecoration(
                labelText: 'Category',

                filled: true,

                fillColor: AppColors.background,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),

              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,

                  child: Text(category, overflow: TextOverflow.ellipsis),
                );
              }).toList(),

              onChanged: _changeCategory,
            ),
          ),

          const SizedBox(width: 14),

          // ======================================================
          // SEARCH BUTTON
          // ======================================================
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _search,
              tooltip: 'Search',
              icon: const Icon(Icons.search, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE CARD
  // ============================================================

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _options.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildTableHeader(),

                Expanded(
                  child: ListView.separated(
                    itemCount: _options.length,

                    separatorBuilder: (_, __) {
                      return Divider(height: 1, color: Colors.grey.shade200);
                    },

                    itemBuilder: (context, index) {
                      return _buildTableRow(_options[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),

      decoration: BoxDecoration(
        color: AppColors.background,

        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),

      child: const Row(
        children: [
          SizedBox(width: 60, child: Text('ID', style: _headerStyle)),

          //Expanded(flex: 2, child: Text('Category', style: _headerStyle)),

          //Expanded(flex: 3, child: Text('Label', style: _headerStyle)),

          Expanded(flex: 3, child: Text('Value', style: _headerStyle)),

          SizedBox(width: 120, child: Text('Actions', style: _headerStyle)),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE ROW
  // ============================================================

  Widget _buildTableRow(Map<String, dynamic> option) {
    final String id = option['id']?.toString() ?? '-';

    final String category = option['category']?.toString() ?? '-';

    final String label = option['label']?.toString() ?? '-';

    final String value = option['value']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      child: Row(
        children: [
          // ======================================================
          // ID
          // ======================================================
          SizedBox(
            width: 60,

            child: Text(
              id,

              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ======================================================
          // CATEGORY
          // ======================================================
          // Expanded(
          //   flex: 2,

          //   child: Align(
          //     alignment: Alignment.centerLeft,

          //     child: _buildCategoryBadge(category),
          //   ),
          // ),

          // // ======================================================
          // // LABEL
          // // ======================================================
          // Expanded(
          //   flex: 3,

          //   child: Text(
          //     label,

          //     overflow: TextOverflow.ellipsis,

          //     style: const TextStyle(
          //       fontSize: 14,
          //       fontWeight: FontWeight.w600,
          //       color: AppColors.textPrimary,
          //     ),
          //   ),
          // ),

          // ======================================================
          // VALUE
          // ======================================================
          Expanded(
            flex: 3,

            child: Text(
              value,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ======================================================
          // ACTIONS
          // ======================================================
          SizedBox(
            width: 120,

            child: Row(
              children: [
                IconButton(
                  tooltip: 'Edit',

                  onPressed: () {
                    _showAddEditDialog(option: option);
                  },

                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),

                IconButton(
                  tooltip: 'Delete',

                  onPressed: _isLoading
                      ? null
                      : () {
                          _deleteOption(option);
                        },

                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
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
  // CATEGORY BADGE
  // ============================================================

  Widget _buildCategoryBadge(String category) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),

        borderRadius: BorderRadius.circular(7),
      ),

      child: Text(
        category,

        overflow: TextOverflow.ellipsis,

        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(Icons.tune_outlined, size: 60, color: Colors.grey.shade400),

          const SizedBox(height: 14),

          const Text(
            'No dropdown options found',

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Try changing your search or category filter.',

            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,

      children: [
        Text(
          'Page $_currentPage of $_totalPages',

          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),

        const SizedBox(width: 12),

        IconButton(
          tooltip: 'Previous',

          onPressed: _currentPage > 1
              ? () {
                  _changePage(_currentPage - 1);
                }
              : null,

          icon: const Icon(Icons.chevron_left),
        ),

        ..._buildPageNumbers(),

        IconButton(
          tooltip: 'Next',

          onPressed: _currentPage < _totalPages
              ? () {
                  _changePage(_currentPage + 1);
                }
              : null,

          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // ============================================================
  // PAGE NUMBERS
  // ============================================================

  List<Widget> _buildPageNumbers() {
    final List<Widget> pages = [];

    int start = _currentPage - 2;

    int end = _currentPage + 2;

    if (start < 1) {
      start = 1;
    }

    if (end > _totalPages) {
      end = _totalPages;
    }

    for (int page = start; page <= end; page++) {
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),

          child: InkWell(
            onTap: () {
              _changePage(page);
            },

            borderRadius: BorderRadius.circular(8),

            child: Container(
              width: 36,
              height: 36,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: page == _currentPage
                    ? AppColors.primary
                    : Colors.transparent,

                borderRadius: BorderRadius.circular(8),
              ),

              child: Text(
                '$page',

                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,

                  color: page == _currentPage
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pages;
  }
}

// ============================================================
// HEADER STYLE
// ============================================================

const TextStyle _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
);
