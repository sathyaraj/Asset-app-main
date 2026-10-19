import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assets_app/core/utils/app_colors.dart';
import 'package:assets_app/core/utils/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assets_app/features/assets/presentation/screens/assets_screen.dart'; // To reuse Asset model if possible

class Location {
  final int id;
  final String type;
  final String site;
  final String building;
  final String area;
  final String floor;
  final String roomName;
  final String roomNumber;
  final String condition;
  final String code;

  Location({
    required this.id,
    required this.type,
    required this.site,
    required this.building,
    required this.area,
    required this.floor,
    required this.roomName,
    required this.roomNumber,
    required this.condition,
    required this.code,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: int.parse(json['id'].toString()),
      type: json['location_type'] ?? '',
      site: json['site_name'] ?? '',
      building: json['building_name'] ?? '',
      area: json['area_zone'] ?? '',
      floor: json['floor'] ?? '',
      roomName: json['room_name'] ?? '',
      roomNumber: json['room_number'] ?? '',
      condition: json['condition'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class LiveInventoryScreen extends ConsumerStatefulWidget {
  const LiveInventoryScreen({super.key});

  @override
  ConsumerState<LiveInventoryScreen> createState() => _LiveInventoryScreenState();
}

class _LiveInventoryScreenState extends ConsumerState<LiveInventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Asset> _assets = [];
  List<Location> _locations = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      _fetchData(isSilent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      
      final assetsResponse = await api.getAssets();
      final locationsResponse = await api.getLocations();

      if (mounted) {
        setState(() {
          if (assetsResponse.statusCode == 200 && assetsResponse.data['status'] == 'success') {
            final List assetData = assetsResponse.data['data'];
            _assets = assetData.map((e) => Asset.fromJson(e)).toList();
          }
          if (locationsResponse.statusCode == 200 && locationsResponse.data['status'] == 'success') {
            final List locationData = locationsResponse.data['data'];
            _locations = locationData.map((e) => Location.fromJson(e)).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live data: $e');
      if (mounted && !isSilent) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Live Inventory',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Locations'),
            Tab(text: 'Assets'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildLocationsList(),
              _buildAssetsList(),
            ],
          ),
    );
  }

  Widget _buildLocationsList() {
    if (_locations.isEmpty) {
      return Center(child: Text('No locations found', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.code,
                    style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  _buildConditionBadge(loc.condition),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${loc.site} - ${loc.building}',
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                '${loc.area}, ${loc.floor}',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.room_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('${loc.roomName} (${loc.roomNumber})', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  const Spacer(),
                  Text(loc.type, style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetsList() {
    if (_assets.isEmpty) {
      return Center(child: Text('No assets found', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.name, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(asset.code, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(asset.status, style: TextStyle(color: _getStatusColor(asset.status), fontWeight: FontWeight.bold, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(asset.locationDisplay.split(',').first, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE': return Colors.greenAccent;
      case 'MAINTENANCE': return Colors.orangeAccent;
      case 'STORED': return Colors.grey;
      default: return Colors.white;
    }
  }

  Widget _buildConditionBadge(String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: condition == 'Excellent' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        condition.toUpperCase(),
        style: TextStyle(
          color: condition == 'Excellent' ? Colors.greenAccent : Colors.orangeAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
