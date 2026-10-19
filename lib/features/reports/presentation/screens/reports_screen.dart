import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:assets_app/core/utils/app_colors.dart';

// IMPORTANT:
// Change this import path if your ApiService file is located elsewhere.
import 'package:assets_app/core/utils/api_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _assets = [];

  double _totalValue = 0.0;
  double _monthlyGrowth = 0.0;

  int _activeCount = 0;
  int _maintenanceCount = 0;
  int _storedCount = 0;
  int _decommissionedCount = 0;

  List<_MonthlyAcquisition> _monthlyAcquisition = [];

  List<Map<String, dynamic>> _recentActivities = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  // ============================================================
  // LOAD REPORT DATA
  // ============================================================

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);

      final response = await apiService.getAssets();

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid response received from server.');
      }

      final success = responseData['success'];

      if (success != true) {
        throw Exception(
          responseData['message']?.toString() ?? 'Unable to load report data.',
        );
      }

      final data = responseData['data'];

      if (data is! List) {
        throw Exception('Invalid asset data received from server.');
      }

      final assets = data
          .whereType<Map>()
          .map((asset) => Map<String, dynamic>.from(asset))
          .toList();

      if (!mounted) return;

      setState(() {
        _assets = assets;

        _calculateReports();

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  // ============================================================
  // CALCULATE REPORTS
  // ============================================================

  void _calculateReports() {
    _calculateTotalValue();
    _calculateMonthlyGrowth();
    _calculateStatusDistribution();
    _calculateAcquisitionTrends();
    _calculateRecentActivities();
  }

  // ============================================================
  // TOTAL ASSET VALUE
  // ============================================================

  void _calculateTotalValue() {
    double total = 0.0;

    for (final asset in _assets) {
      final purchaseCost = _toDouble(asset['purchase_cost']);
      final quantity = _toInt(asset['quantity'], defaultValue: 1);

      total += purchaseCost * quantity;
    }

    _totalValue = total;
  }

  // ============================================================
  // MONTHLY GROWTH
  //
  // Current month purchase value vs previous month purchase value.
  // ============================================================

  void _calculateMonthlyGrowth() {
    final now = DateTime.now();

    final currentMonth = DateTime(now.year, now.month, 1);

    final previousMonth = DateTime(now.year, now.month - 1, 1);

    double currentValue = 0.0;
    double previousValue = 0.0;

    for (final asset in _assets) {
      final purchaseDate = _parseDate(asset['purchase_date']);

      if (purchaseDate == null) {
        continue;
      }

      final purchaseCost = _toDouble(asset['purchase_cost']);
      final quantity = _toInt(asset['quantity'], defaultValue: 1);

      final value = purchaseCost * quantity;

      if (purchaseDate.year == currentMonth.year &&
          purchaseDate.month == currentMonth.month) {
        currentValue += value;
      } else if (purchaseDate.year == previousMonth.year &&
          purchaseDate.month == previousMonth.month) {
        previousValue += value;
      }
    }

    if (previousValue == 0) {
      if (currentValue > 0) {
        _monthlyGrowth = 100.0;
      } else {
        _monthlyGrowth = 0.0;
      }

      return;
    }

    _monthlyGrowth = ((currentValue - previousValue) / previousValue) * 100;
  }

  // ============================================================
  // STATUS DISTRIBUTION
  // ============================================================

  void _calculateStatusDistribution() {
    int active = 0;
    int maintenance = 0;
    int stored = 0;

    for (final asset in _assets) {
      final status = asset['status']?.toString().trim().toUpperCase() ?? '';

      final quantity = _toInt(asset['quantity'], defaultValue: 1);

      switch (status) {
        case 'ACTIVE':
          active += quantity;
          break;

        case 'MAINTENANCE':
          maintenance += quantity;
          break;

        case 'STORED':
          stored += quantity;
          break;
      }
    }

    _activeCount = active;
    _maintenanceCount = maintenance;
    _storedCount = stored;

    // Your database enum currently does not contain DECOMMISSIONED.
    _decommissionedCount = 0;
  }

  // ============================================================
  // ASSET ACQUISITION TRENDS
  //
  // Shows last 6 months.
  // ============================================================

  void _calculateAcquisitionTrends() {
    final now = DateTime.now();

    final List<_MonthlyAcquisition> result = [];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);

      int count = 0;

      for (final asset in _assets) {
        final purchaseDate = _parseDate(asset['purchase_date']);

        if (purchaseDate == null) {
          continue;
        }

        if (purchaseDate.year == date.year &&
            purchaseDate.month == date.month) {
          count += _toInt(asset['quantity'], defaultValue: 1);
        }
      }

      result.add(_MonthlyAcquisition(date: date, count: count));
    }

    _monthlyAcquisition = result;
  }

  // ============================================================
  // RECENT ACTIVITIES
  // ============================================================

  void _calculateRecentActivities() {
    final sortedAssets = List<Map<String, dynamic>>.from(_assets);

    sortedAssets.sort((a, b) {
      final dateA =
          _parseDate(a['last_updated']) ??
          _parseDate(a['created_at']) ??
          DateTime(1970);

      final dateB =
          _parseDate(b['last_updated']) ??
          _parseDate(b['created_at']) ??
          DateTime(1970);

      return dateB.compareTo(dateA);
    });

    _recentActivities = sortedAssets.take(5).toList();
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
          'Reports & Analytics',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _showDateInfo,
            icon: const Icon(
              Icons.date_range_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: AppColors.primary,

      onRefresh: _loadReports,

      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildSummaryGrid(),

            const SizedBox(height: 24),

            _buildChartSection(
              context,
              'Asset Acquisition Trends',
              _buildLineChart(),
            ),

            const SizedBox(height: 24),

            _buildChartSection(
              context,
              'Status Distribution',
              _buildPieChart(),
            ),

            const SizedBox(height: 24),

            _buildRecentLogsSection(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 50,
            ),

            const SizedBox(height: 16),

            Text(
              _errorMessage ?? 'Unable to load reports.',
              textAlign: TextAlign.center,

              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadReports,

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

  // ============================================================
  // SUMMARY GRID
  // ============================================================

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      childAspectRatio: 1.5,

      crossAxisSpacing: 12,

      mainAxisSpacing: 12,

      children: [
        _buildMiniCard(
          'Total Value',
          _formatCurrency(_totalValue),
          Icons.account_balance_wallet_outlined,
        ),

        _buildMiniCard(
          'Monthly Growth',
          '${_monthlyGrowth >= 0 ? '+' : ''}${_monthlyGrowth.toStringAsFixed(1)}%',
          Icons.trending_up,
          isTrend: _monthlyGrowth >= 0,
        ),
      ],
    );
  }

  // ============================================================
  // MINI CARD
  // ============================================================

  Widget _buildMiniCard(
    String title,
    String value,
    IconData icon, {
    bool isTrend = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,

                  overflow: TextOverflow.ellipsis,

                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,

            overflow: TextOverflow.ellipsis,

            style: GoogleFonts.outfit(
              color: isTrend
                  ? AppColors.activeGreenText
                  : AppColors.textPrimary,

              fontSize: 20,

              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART SECTION
  // ============================================================

  Widget _buildChartSection(BuildContext context, String title, Widget chart) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,

              fontSize: 18,

              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  // ============================================================
  // LINE CHART
  // ============================================================

  Widget _buildLineChart() {
    if (_monthlyAcquisition.isEmpty) {
      return _buildNoDataWidget();
    }

    final maxCount = _monthlyAcquisition.fold<int>(
      0,
      (max, item) => item.count > max ? item.count : max,
    );

    final maxY = maxCount <= 0
        ? 5.0
        : (maxCount + (maxCount * 0.2)).ceilToDouble();

    return LineChart(
      LineChartData(
        minX: 0,

        maxX: (_monthlyAcquisition.length - 1).toDouble(),

        minY: 0,

        maxY: maxY,

        gridData: const FlGridData(show: false),

        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,

              reservedSize: 30,

              interval: 1,

              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= _monthlyAcquisition.length) {
                  return const SizedBox.shrink();
                }

                final date = _monthlyAcquisition[index].date;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),

                  child: Text(
                    DateFormat('MMM').format(date),

                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        borderData: FlBorderData(show: false),

        lineTouchData: LineTouchData(
          enabled: true,

          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();

                final item = _monthlyAcquisition[index];

                return LineTooltipItem(
                  '${DateFormat('MMM yyyy').format(item.date)}\n${item.count} assets',

                  GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: List.generate(_monthlyAcquisition.length, (index) {
              return FlSpot(
                index.toDouble(),
                _monthlyAcquisition[index].count.toDouble(),
              );
            }),

            isCurved: true,

            color: AppColors.primary,

            barWidth: 4,

            isStrokeCapRound: true,

            dotData: const FlDotData(show: false),

            belowBarData: BarAreaData(
              show: true,

              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PIE CHART
  // ============================================================

  Widget _buildPieChart() {
    final total =
        _activeCount + _maintenanceCount + _storedCount + _decommissionedCount;

    if (total == 0) {
      return _buildNoDataWidget();
    }

    return Row(
      children: [
        Expanded(
          flex: 1,

          child: PieChart(
            PieChartData(
              sectionsSpace: 4,

              centerSpaceRadius: 40,

              sections: [
                if (_activeCount > 0)
                  PieChartSectionData(
                    color: AppColors.primary,

                    value: _activeCount.toDouble(),

                    showTitle: false,

                    radius: 10,
                  ),

                if (_maintenanceCount > 0)
                  PieChartSectionData(
                    color: AppColors.warning,

                    value: _maintenanceCount.toDouble(),

                    showTitle: false,

                    radius: 10,
                  ),

                if (_storedCount > 0)
                  PieChartSectionData(
                    color: AppColors.storedGreyText,

                    value: _storedCount.toDouble(),

                    showTitle: false,

                    radius: 10,
                  ),

                if (_decommissionedCount > 0)
                  PieChartSectionData(
                    color: AppColors.error,

                    value: _decommissionedCount.toDouble(),

                    showTitle: false,

                    radius: 10,
                  ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 1,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              _buildLegend('Active', AppColors.primary, _activeCount),

              _buildLegend('Maintenance', AppColors.warning, _maintenanceCount),

              _buildLegend('Stored', AppColors.storedGreyText, _storedCount),

              _buildLegend(
                'Decommissioned',
                AppColors.error,
                _decommissionedCount,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegend(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(
        children: [
          Container(
            width: 8,

            height: 8,

            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              title,

              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),

          Text(
            count.toString(),

            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,

              fontSize: 12,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT ACTIVITIES
  // ============================================================

  Widget _buildRecentLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'Recent Activities',

          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,

            fontSize: 18,

            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        if (_recentActivities.isEmpty)
          _buildNoActivitiesWidget()
        else
          ..._recentActivities.map((asset) => _buildDynamicLogItem(asset)),
      ],
    );
  }

  // ============================================================
  // DYNAMIC LOG ITEM
  // ============================================================

  Widget _buildDynamicLogItem(Map<String, dynamic> asset) {
    final assetName = asset['asset_name']?.toString().trim();

    final name = assetName == null || assetName.isEmpty
        ? 'Unknown Asset'
        : assetName;

    final status = asset['status']?.toString().trim().toUpperCase() ?? '';

    final createdAt = _parseDate(asset['created_at']);

    final updatedAt = _parseDate(asset['last_updated']);

    String subtitle;

    if (updatedAt != null &&
        createdAt != null &&
        updatedAt.isAfter(createdAt)) {
      subtitle = _getActivityFromStatus(status);
    } else {
      subtitle = 'New asset registered';
    }

    final activityDate = updatedAt ?? createdAt;

    final time = activityDate == null ? '' : _formatRelativeTime(activityDate);

    return _buildLogItem(name, subtitle, time);
  }

  // ============================================================
  // ACTIVITY DESCRIPTION
  // ============================================================

  String _getActivityFromStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Asset status is Active';

      case 'MAINTENANCE':
        return 'Asset is under Maintenance';

      case 'STORED':
        return 'Asset moved to Storage';

      case 'DECOMMISSIONED':
        return 'Asset Decommissioned';

      default:
        return 'Asset information updated';
    }
  }

  // ============================================================
  // LOG ITEM UI
  // ============================================================

  Widget _buildLogItem(String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.history,

              color: AppColors.primary,

              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,

                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,

                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            time,

            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,

              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO DATA
  // ============================================================

  Widget _buildNoDataWidget() {
    return Center(
      child: Text(
        'No data available',

        style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  // ============================================================
  // NO ACTIVITIES
  // ============================================================

  Widget _buildNoActivitiesWidget() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(16),
      ),

      child: Center(
        child: Text(
          'No recent activities',

          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  void _showDateInfo() {
    showModalBottomSheet(
      context: context,

      backgroundColor: AppColors.cardBackground,

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Report Period',

                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,

                    fontSize: 18,

                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Acquisition trends show the last 6 months based on purchase date.',

                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,

                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),

                    child: const Text('Close'),
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
  // CURRENCY FORMAT
  // ============================================================

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }

    return '\$${value.toStringAsFixed(2)}';
  }

  // ============================================================
  // INTEGER CONVERSION
  // ============================================================

  int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) {
      return defaultValue;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? defaultValue;
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();

    final difference = now.difference(date);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return DateFormat('dd MMM').format(date);
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.isEmpty) {
      return 'Unable to load reports. Please try again.';
    }

    return message;
  }
}

// ============================================================
// MONTHLY ACQUISITION MODEL
// ============================================================

class _MonthlyAcquisition {
  final DateTime date;
  final int count;

  const _MonthlyAcquisition({required this.date, required this.count});
}
