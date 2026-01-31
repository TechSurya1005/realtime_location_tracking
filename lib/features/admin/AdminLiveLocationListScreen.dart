import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';

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

  // Google Maps
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Current stats
  double? _currentLat;
  double? _currentLng;
  double? _currentAccuracy;
  String _currentAddress = "Fetching location...";
  DateTime? _lastUpdated;

  // Track camera
  bool _shouldFollowUser = true;

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

      _processUpdate(user);
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
    final DateTime? updatedTime = updatedAtStr != null
        ? DateTime.tryParse(updatedAtStr)
        : null;

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

    // Skip if location hasn't effectively changed to save geocoding quota & renders
    if (_currentLat == lat && _currentLng == lng) {
      if (mounted && _lastUpdated != updatedTime) {
        setState(() {
          _lastUpdated = updatedTime;
        });
      }
      return;
    }

    // Geocode to get human-readable address
    String address = _currentAddress;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addressParts = <String>[];

        String streetName = p.thoroughfare ?? '';
        if (streetName.isEmpty || _isPlusCode(streetName)) {
          if (!_isPlusCode(p.name)) {
            streetName = p.name ?? '';
          } else {
            streetName = '';
          }
        }

        if (streetName.isNotEmpty) addressParts.add(streetName);
        if (p.subLocality?.isNotEmpty == true) addressParts.add(p.subLocality!);
        if (p.locality?.isNotEmpty == true) addressParts.add(p.locality!);

        if (addressParts.isNotEmpty) {
          address = addressParts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Geocoding error: $e');
    }

    if (mounted) {
      setState(() {
        _isLive = live;
        _waitingForFirstLocation = false;
        _currentLat = lat;
        _currentLng = lng;
        _currentAccuracy = accuracy;
        _currentAddress = address;
        _lastUpdated = updatedTime ?? DateTime.now();

        _updateMapMarkers(lat, lng);
      });
    }
  }

  void _updateMapMarkers(double lat, double lng) {
    final marker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: widget.userName,
        snippet: 'Last active: ${_formatTime(_lastUpdated)}',
      ),
    );

    _markers.clear();
    _markers.add(marker);

    if (_shouldFollowUser && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16),
        ),
      );
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('hh:mm:ss a').format(dt);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        toolbarHeight: 0, // Collapse appbar, we'll use a custom overlay
        backgroundColor: AppColors.primary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // 1. THE MAP
          _waitingForFirstLocation
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLat ?? 0, _currentLng ?? 0),
                    zoom: 15,
                  ),
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Force initial camera update if we have data
                    if (_currentLat != null && _currentLng != null) {
                      _mapController!.moveCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(_currentLat!, _currentLng!),
                          16,
                        ),
                      );
                    }
                  },
                ),

          // 2. HEADER OVERLAY
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isLive ? AppColors.accent : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isLive ? 'LIVE' : 'OFFLINE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 14),
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
                ],
              ),
            ),
          ),

          // 3. BOTTOM INFO CARD
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "CURRENT LOCATION",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _shouldFollowUser = !_shouldFollowUser;
                          });
                          if (_shouldFollowUser && _currentLat != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(_currentLat!, _currentLng!),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          _shouldFollowUser
                              ? Icons.gps_fixed
                              : Icons.gps_not_fixed,
                          color: _shouldFollowUser
                              ? AppColors.primary
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.access_time_filled_rounded,
                        _lastUpdated != null
                            ? DateFormat('hh:mm:ss a').format(_lastUpdated!)
                            : '--:--',
                      ),
                      const SizedBox(width: 10),
                      if (_currentAccuracy != null)
                        _buildInfoChip(
                          Icons.radar,
                          '±${_currentAccuracy!.toStringAsFixed(0)}m',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
