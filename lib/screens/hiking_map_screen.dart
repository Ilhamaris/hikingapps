import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import '../models/bounding_box.dart';
import '../services/gpx_service.dart';
import '../services/bounding_box_calculator.dart';
import '../config/tile_config.dart';

/// Layar untuk menampilkan peta hiking dengan rute GPX
class HikingMapScreen extends StatefulWidget {
  final Mountain mountain;
  final HikingRoute route;
  final double bodyWeight;
  final double bagWeight;

  const HikingMapScreen({
    super.key,
    required this.mountain,
    required this.route,
    required this.bodyWeight,
    required this.bagWeight,
  });

  @override
  State<HikingMapScreen> createState() => _HikingMapScreenState();
}

class _HikingMapScreenState extends State<HikingMapScreen> {
  late MapController mapController;
  List<LatLng> routePoints = [];
  Map<String, LatLng> waypoints = {};
  bool isLoading = true;
  String? errorMessage;
  BoundingBox? routeBounds;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _loadGPXData();
  }

  /// Load GPX track points and waypoints
  Future<void> _loadGPXData() async {
    try {
      // Load track points
      final trackPoints = await GPXService.loadGPXTrack(
        widget.route.gpxFileName,
      );

      // Load waypoints
      final waypointsList = await GPXService.loadGPXWaypoints(
        widget.route.gpxFileName,
      );

      if (mounted) {
        // Calculate bounds from route for later caching
        if (trackPoints.isNotEmpty) {
          final routeBoundingBox = BoundingBoxCalculator.calculateBoundingBox(
            trackPoints,
          );
          routeBounds = routeBoundingBox;
        }

        setState(() {
          routePoints = trackPoints;
          waypoints = waypointsList;
          isLoading = false;
        });

        // Fit camera after loading data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitCameraToRoute();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat data GPX: $e';
        });
      }
    }
  }

  /// Fit camera to show entire route with padding
  void _fitCameraToRoute() {
    if (routePoints.isEmpty) return;

    final boundingBox = BoundingBoxCalculator.calculateBoundingBox(routePoints);
    final bounds = boundingBox.toLatLngBounds();

    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Peta Hiking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(errorMessage!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      _loadGPXData();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(0, 0),
                    initialZoom: 13,
                  ),
                  children: [
                    // OpenStreetMap tile layer (online only)
                    TileLayer(
                      urlTemplate: TileConfig.openStreetMapUrl,
                      userAgentPackageName: TileConfig.userAgent,
                    ),

                    // Route polyline layer
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 4,
                            color: Colors.red,
                          ),
                        ],
                      ),

                    // Waypoints marker layer
                    if (waypoints.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          for (final waypoint in waypoints.entries)
                            Marker(
                              point: waypoint.value,
                              width: 80,
                              height: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      waypoint.key,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),

                // Info card at bottom
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.route.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.monitor_weight,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Berat: ${widget.bodyWeight.toStringAsFixed(0)} kg + ${widget.bagWeight.toStringAsFixed(0)} kg tas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Jarak: ${widget.route.distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
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
}
