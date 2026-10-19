import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assets_app/core/utils/api_service.dart';
import 'package:assets_app/core/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

final dashboardStatsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getDashboardStats();
  //return response.data;

 final responseData = response.data;

  if (responseData is! Map<String, dynamic>) {
    throw Exception('Invalid dashboard response.');
  }

  if (responseData['success'] != true) {
    throw Exception(
      responseData['message']?.toString() ??
          'Unable to load dashboard statistics.',
    );
  }

  final data = responseData['data'];

  if (data is! List) {
    throw Exception('Invalid dashboard data.');
  }

  return data;

});

final dashboardSearchProvider = StateProvider<String>((ref) => '');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final searchQuery = ref.watch(dashboardSearchProvider).toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Asset Overview',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final filteredStats = stats.where((item) {
            final name = (item['asset_class'] ?? '').toString().toLowerCase();
            final code = (item['class_code'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) || code.contains(searchQuery);
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardStatsProvider.future),
            child: Column(
              children: [
                _buildSearchBar(ref),
                Expanded(
                  child: filteredStats.isEmpty
                      ? Center(
                          child: Text(
                            'No matching asset classes',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStats.length,
                          itemBuilder: (context, index) {
                            final item = filteredStats[index];
                            return _buildStatCard(
                              item['asset_class'] ?? 'N/A',
                              item['class_code'] ?? 'N/A',
                              item['total_assets']?.toString() ?? '0',
                              _getColorForIndex(index),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add asset
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) => ref.read(dashboardSearchProvider.notifier).state = value,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search asset class or code...',
          hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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

  Widget _buildStatCard(String title, String code, String count, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Assets',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.primary,
      AppColors.activeGreenText,
      AppColors.maintenanceOrangeText,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];
    return colors[index % colors.length];
  }
}
