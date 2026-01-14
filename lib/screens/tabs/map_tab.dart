import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../providers/robot_provider.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();

  // Safe fallback
  static const LatLng _defaultPosition = LatLng(0, 0);

  String _currentAddress = 'Fetching location details...';
  LatLng? _lastAddressPos;
  bool _shouldFollowUser = true; // Auto-center map when robot moves

  @override
  Widget build(BuildContext context) {
    return Consumer<RobotProvider>(
      builder: (context, robot, child) {
        final hasFix = robot.hasGpsFix;
        final position = hasFix
            ? LatLng(robot.latitude, robot.longitude)
            : _defaultPosition;

        // Auto-follow logic
        if (hasFix && _shouldFollowUser) {
          _mapController.move(position, 17.0);
          _updateAddress(position);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: hasFix ? 17.0 : 2.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onPositionChanged: (pos, hasGesture) {
                    if (hasGesture) {
                      // If user drags map, stop auto-following
                      setState(() => _shouldFollowUser = false);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    // OpenStreetMap Standard Tile Server (Free)
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.humosync_safety',
                    // Use a slightly dark filter to match app theme if possible,
                    // otherwise it will be standard light map.
                    // FlutterMap doesn't have built-in dark mode for raster tiles
                    // unless we use a dark tile provider (e.g. CartoDB Dark Matter).
                    // For now, let's stick to standard OSM for reliability.
                  ),

                  // Robot Marker
                  if (hasFix)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 80,
                          height: 80,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF06B6D4,
                                  ).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF06B6D4),
                                    width: 2,
                                  ),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.robot,
                                  color: Color(0xFF06B6D4),
                                  size: 20,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF06B6D4),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // Accuracy Circle
                  if (hasFix)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: position,
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                          borderStrokeWidth: 1,
                          borderColor: const Color(
                            0xFF06B6D4,
                          ).withValues(alpha: 0.3),
                          useRadiusInMeter: true,
                          radius: robot.gpsAccuracy > 0
                              ? robot.gpsAccuracy
                              : 10, // Minimum 10m visual
                        ),
                      ],
                    ),
                ],
              ),

              // Status Overlay
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasFix
                              ? const Color(0xFF06B6D4).withValues(alpha: 0.1)
                              : const Color(0xFF64748B).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.satelliteDish,
                          color: hasFix
                              ? const Color(0xFF06B6D4)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasFix
                                  ? 'GPS LINK ACTIVE (OSM)'
                                  : 'SEARCHING FOR SATELLITES...',
                              style: GoogleFonts.inter(
                                color: hasFix
                                    ? const Color(0xFF06B6D4)
                                    : const Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (hasFix) ...[
                              Text(
                                _currentAddress,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${robot.latitude.toStringAsFixed(6)}, ${robot.longitude.toStringAsFixed(6)} • Acc: ${robot.gpsAccuracy.toStringAsFixed(1)}m',
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ] else
                              Text(
                                'Waiting for GPS fix from robot...',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Re-center button
              if (hasFix)
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() => _shouldFollowUser = true);
                      _mapController.move(position, 17.0);
                    },
                    backgroundColor: const Color(0xFF06B6D4),
                    child: const FaIcon(
                      FontAwesomeIcons.locationCrosshairs,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Attribution (Required for OSM)
              Positioned(
                bottom: 5,
                right: 50,
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAddress(LatLng pos) async {
    // Debounce updates to avoid quota limits
    if (_lastAddressPos != null) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        pos,
        _lastAddressPos!,
      );
      if (distance < 10) return; // Only update if moved > 10m
    }

    _lastAddressPos = pos;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        // Construct a readable address string
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += place.locality!;
        }

        // Fallback
        if (address.isEmpty) address = 'Unknown Location Area';

        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Location identified";
        });
      }
      debugPrint("Geocoding error: $e");
    }
  }
}
