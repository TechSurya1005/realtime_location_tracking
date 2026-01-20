import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';

class AdminLiveLocationListScreen extends StatefulWidget {
  final String userAuthUid;
  final String userName;

  const AdminLiveLocationListScreen({
    super.key,
    required this.userAuthUid,
    required this.userName,
  });

  @override
  State<AdminLiveLocationListScreen> createState() =>
      _AdminLiveLocationListScreenState();
}

class _AdminLiveLocationListScreenState
    extends State<AdminLiveLocationListScreen> {
  final _supabase = Supabase.instance.client;

  StreamSubscription? _subscription;
  Timer? _pollingTimer;
  bool _isLive = true;
  bool _waitingForFirstLocation = true;

  // List to store all location updates - NO MAX LIMIT
  final List<LocationEntry> _locationList = [];

  // Track last location to avoid duplicates
  double? _lastLat;
  double? _lastLng;
  static const double _minDistanceForNewEntry =
      5.0; // 5 meters for "perfect" tracking

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLiveSnapshotFirst();
    });
  }

  void _setupRealtime() {
    _fetchLiveSnapshotFirst();

    _subscription = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('auth_uid', widget.userAuthUid)
        .limit(1)
        .listen((data) {
          if (data.isNotEmpty) {
            _processUpdate(data.first);
          }
        });
  }

  Future<void> _fetchLiveSnapshotFirst() async {
    try {
      final user = await _supabase
          .from('users')
          .select(
            'live_lat, live_lng, live_updated_at, live_accuracy, is_live_sharing',
          )
          .eq('auth_uid', widget.userAuthUid)
          .single();

      if (user['live_lat'] != null) {
        await _processUpdate(user);
      }
    } catch (e) {
      debugPrint('ℹ️ Snapshot fetch error: $e');
    }
  }

  // Helper to filter out Google Plus Codes (e.g. 7MHF+8H6)
  bool _isPlusCode(String? s) {
    if (s == null || s.isEmpty) return false;
    return s.contains('+') && s.length < 15;
  }

  Future<void> _processUpdate(Map<String, dynamic> data) async {
    final bool live = data['is_live_sharing'] == true;
    final double? lat = data['live_lat'] != null
        ? (data['live_lat'] as num).toDouble()
        : null;
    final double? lng = data['live_lng'] != null
        ? (data['live_lng'] as num).toDouble()
        : null;
    final double? accuracy = data['live_accuracy'] != null
        ? (data['live_accuracy'] as num).toDouble()
        : null;
    final String? updatedAtStr = data['live_updated_at'];

    if (!live && lat == null) {
      if (mounted) {
        setState(() {
          _isLive = false;
          _waitingForFirstLocation = false;
        });
      }
      return;
    }

    if (lat == null || lng == null) return;

    // Check if user moved enough to add new entry
    bool shouldAddNewEntry = true;
    if (_lastLat != null && _lastLng != null) {
      final distance = _calculateDistance(_lastLat!, _lastLng!, lat, lng);
      shouldAddNewEntry = distance > _minDistanceForNewEntry;
    }

    if (!shouldAddNewEntry) {
      if (_locationList.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLive = live;
            final latestEntry = _locationList[0];
            _locationList[0] = LocationEntry(
              timestamp: updatedAtStr != null
                  ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
                  : DateTime.now(),
              latitude: latestEntry.latitude,
              longitude: latestEntry.longitude,
              accuracy: accuracy ?? latestEntry.accuracy,
              address: latestEntry.address,
              street: latestEntry.street,
              locality: latestEntry.locality,
              city: latestEntry.city,
              country: latestEntry.country,
            );
          });
        }
      }
      return;
    }

    // Geocode to get human-readable address
    Placemark? placemark;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      placemark = placemarks.isNotEmpty ? placemarks.first : null;
    } catch (e) {
      debugPrint('⚠️ Geocoding error: $e');
    }

    // Build cleaner address, avoiding Plus Codes (e.g. 7MHF+8H6)
    final addressParts = <String>[];
    final p = placemark;

    if (p != null) {
      // 1. Try to get a real street name (thoroughfare)
      String streetName = p.thoroughfare ?? '';
      if (streetName.isEmpty || _isPlusCode(streetName)) {
        // Fallback to name but only if it's not a plus code
        if (!_isPlusCode(p.name)) {
          streetName = p.name ?? '';
        } else {
          streetName = '';
        }
      }

      if (streetName.isNotEmpty) addressParts.add(streetName);
      if (p.subLocality != null && p.subLocality!.isNotEmpty) {
        addressParts.add(p.subLocality!);
      }
      if (p.locality != null && p.locality!.isNotEmpty) {
        addressParts.add(p.locality!);
      }
      if (p.subAdministrativeArea != null &&
          p.subAdministrativeArea!.isNotEmpty) {
        addressParts.add(p.subAdministrativeArea!);
      }
      if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
        addressParts.add(p.administrativeArea!);
      }
      if (p.country != null && p.country!.isNotEmpty) {
        addressParts.add(p.country!);
      }
    }

    final address = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : '📍 ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

    final newEntry = LocationEntry(
      timestamp: updatedAtStr != null
          ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
          : DateTime.now(),
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      address: address,
      street: placemark?.street ?? '',
      locality: placemark?.locality ?? '',
      city: placemark?.administrativeArea ?? '',
      country: placemark?.country ?? '',
    );

    if (mounted) {
      setState(() {
        _isLive = live;
        _waitingForFirstLocation = false;
        _lastLat = lat;
        _lastLng = lng;
        _locationList.insert(0, newEntry);
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  @override
  void dispose() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        backgroundColor: AppColors.primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.ktGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Location Feed',
              style: AppTextStyle.titleMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isLive ? AppColors.accent : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (_isLive)
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.userName.toUpperCase(),
                  style: AppTextStyle.labelMediumStyle(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '5s',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: !_isLive && _locationList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off_rounded,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'User is Offline',
                    style: AppTextStyle.titleMediumStyle(
                      context,
                    ).copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _waitingForFirstLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Fetching live data...'),
                ],
              ),
            )
          : _buildLocationList(),
    );
  }

  Widget _buildLocationList() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.radar_rounded,
                color: _isLive ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLive ? 'Live Tracking Active' : 'Tracking Inactive',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isLive ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    const Text(
                      'Refreshing every 5 seconds',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                'POINTS: ${_locationList.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _locationList.isEmpty
              ? const Center(child: Text('Waiting for movement...'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _locationList.length,
                  itemBuilder: (context, index) {
                    final displayIndex = _locationList.length - index;
                    final entry = _locationList[index];
                    final isLatest = index == 0;
                    return _buildLocationCard(entry, displayIndex, isLatest);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    LocationEntry entry,
    int displayIndex,
    bool isLatest,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLatest && _isLive
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Update #$displayIndex',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  DateFormat('hh:mm:ss a').format(entry.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.address,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  Icons.gps_fixed_rounded,
                  '${entry.latitude.toStringAsFixed(5)}, ${entry.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(width: 8),
                if (entry.accuracy != null)
                  _buildInfoChip(
                    Icons.location_on_rounded,
                    '±${entry.accuracy!.toStringAsFixed(1)}m',
                  ),
              ],
            ),
            if (isLatest && _isLive) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'LATEST POSITION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class LocationEntry {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String address;
  final String street;
  final String locality;
  final String city;
  final String country;

  LocationEntry({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.address,
    required this.street,
    required this.locality,
    required this.city,
    required this.country,
  });
}
