import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import '../models/route_point.dart';
import '../models/segment_result.dart';
import '../services/route_loader.dart';
import '../services/inference_service.dart';
import '../config/tile_config.dart';
import '../services/location_service.dart';
import 'dart:async';

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
  LatLng? currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;

  // points loaded from JSON
  List<RoutePoint> _routePoints = [];
  bool isLoading = true;

  // inference service and results
  late InferenceService _inferenceService;
  bool _isInferenceInitialized = false;
  bool _isEstimating = false;
  List<SegmentResult> _segmentResults = [];

  final GlobalKey _sheetKey = GlobalKey();
  final ValueNotifier<double> _sheetHeight = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initLocation();

    // prepare inference service
    _inferenceService = InferenceService();
    _initializeInference();

    _loadRoute();
  }

  Future<void> _initLocation() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          currentLocation = loc;
          isLoading = false;
        });
        // ensure camera adjusts once map is visible
        if (_routePoints.isNotEmpty) {
          _fitToRoute();
        }
      }

      _locationSubscription = LocationService.getLocationStream().listen((loc) {
        if (mounted) {
          setState(() {
            currentLocation = loc;
          });
        }
      }, onError: (_) {});
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Akhiri Pendakian'),
          content: const Text('Aapakah anda ingin mengakhiri pendakian?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeInference() async {
    try {
      await _inferenceService.initialize();
      setState(() {
        _isInferenceInitialized = true;
      });
      // try to compute if route already loaded
      _attemptEstimation();
    } catch (e) {
      debugPrint('Inference init failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inference init error: $e')),
        );
      }
    }
  }

  Future<void> _attemptEstimation() async {
    if (!_isInferenceInitialized || _routePoints.isEmpty) return;
    if (_isEstimating) return;
    _isEstimating = true;

    try {
      // convert route points to raw segment maps
      final rawSegments = _routePoints.map((p) {
        return {
          'delta_dist_m': p.deltaDist,
          'delta_elev_m': p.deltaElev,
          'slope_deg': p.slopeDeg,
        };
      }).toList();

      final results = _inferenceService.processSegments(rawSegments);
      if (mounted) {
        setState(() {
          _segmentResults = results;
        });
      }
    } catch (e) {
      debugPrint('Estimation processing failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estimation error: $e')),
        );
      }
    } finally {
      _isEstimating = false;
    }
  }

  Future<void> _loadRoute() async {
    String path = 'assets/routes/${widget.route.id}.json';
    List<RoutePoint> pts = [];
    try {
      pts = await RouteLoader.loadRoute(path);
      if (pts.isEmpty) {
        debugPrint('route loader: $path contained no points');
      } else {
        debugPrint('route loader: loaded ${pts.length} points from $path');
      }
    } catch (e, st) {
      debugPrint('failed to load route from $path: $e');
      debugPrint('$st');
    }

    // fallback to full route file if primary load failed or returned nothing
    if (pts.isEmpty) {
      const fallback = 'assets/routes/route_glonggong_mlaten.json';
      try {
        pts = await RouteLoader.loadRoute(fallback);
        debugPrint(
          'fallback loader: loaded ${pts.length} points from $fallback',
        );
        path = fallback;
      } catch (e, st) {
        debugPrint('fallback load also failed: $e');
        debugPrint('$st');
      }
    }

    if (mounted) {
      setState(() {
        _routePoints = pts;
      });
      _fitToRoute();
      _attemptEstimation();
    }
  }

  void _fitToRoute() {
    if (_routePoints.isEmpty) return;
    final points = _routePoints.map((p) => LatLng(p.lat, p.lon)).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var bounds = LatLngBounds.fromPoints(points);
      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
      );
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _sheetHeight.dispose();
    _inferenceService.dispose();
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
          onPressed: _showExitConfirmation,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                // prepare route layers
                final routeLatLng = _routePoints
                    .map((p) => LatLng(p.lat, p.lon))
                    .toList();
                final routeMarkers = _routePoints
                    .where((p) => p.name != null)
                    .map(
                      (p) => Marker(
                        width: 100,
                        height: 50,
                        point: LatLng(p.lat, p.lon),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p == _routePoints.last
                                  ? Icons.flag
                                  : Icons.house_siding,
                              size: 30,
                              color: Colors.green,
                            ),
                            Text(
                              p.name ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList();

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(0, 0),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: TileConfig.openStreetMapUrl,
                          userAgentPackageName: TileConfig.userAgent,
                        ),
                        if (routeLatLng.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routeLatLng,
                                strokeWidth: 4,
                                color: Colors.red,
                              ),
                            ],
                          ),
                        if (routeMarkers.isNotEmpty)
                          MarkerLayer(markers: routeMarkers),
                        if (currentLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentLocation!,
                                width: 22,
                                height: 22,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    DraggableScrollableSheet(
                      initialChildSize: 0.2,
                      minChildSize: 0.2,
                      maxChildSize: 0.85,
                      builder: (context, scrollController) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final renderBox = _sheetKey.currentContext?.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            _sheetHeight.value = renderBox.size.height;
                          }
                        });
                        // keep original index so we can map back to segment results
                    final postsWithIndex = _routePoints
                        .asMap()
                        .entries
                        .where((e) => e.value.name != null)
                        .toList();
                    return Container(
                          key: _sheetKey,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Handle
                              Container(
                                height: 4,
                                width: 40,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  itemCount: postsWithIndex.length,
                                  itemBuilder: (context, index) {
                                    final entry = postsWithIndex[index];
                                    final p = entry.value;
                                    final originalIdx = entry.key;
                                    int estimatedTime = 0;
                                    if (_segmentResults.isNotEmpty &&
                                        originalIdx < _segmentResults.length) {
                                      estimatedTime = (_segmentResults[originalIdx]
                                          .cumulative / 60)
                                          .round();
                                    }

                                    return ListTile(
                                      title: Text(
                                        'Pos ${index + 1}: ${p.name ?? 'Post ${index + 1}'}',
                                      ),
                                      subtitle: _isEstimating
                                          ? Row(
                                              children: const [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    strokeCap: StrokeCap.round,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text('Estimating...'),
                                              ],
                                            )
                                          : Text(
                                              'Estimated time: $estimatedTime min',
                                            ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    ValueListenableBuilder<double>(
                      valueListenable: _sheetHeight,
                      builder: (context, height, child) {
                        return Positioned(
                          right: 20,
                          bottom: height + 20,
                          child: FloatingActionButton(
                            heroTag: 'loc_main_btn',
                            backgroundColor: Colors.green,
                            onPressed: () {
                              if (currentLocation != null) {
                                mapController.move(currentLocation!, 17);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Lokasi tidak tersedia. Pastikan izin lokasi diberikan.',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
