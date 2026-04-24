import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import '../models/route_point.dart';
import '../models/segment_result.dart';
import '../models/hiking_history.dart';
import '../services/mountain_loader.dart';
import '../services/inference_service.dart';
import '../config/tile_config.dart';
import '../services/location_service.dart';
import '../services/history_service.dart';
import 'dart:async';

// Halaman utama yang menampilkan peta jalur pendakian, posisi
// pengguna, dan estimasi waktu ke setiap pos berdasarkan model ML.

class HikingMapScreen extends StatefulWidget {
  // Data gunung yang dipilih
  final Mountain mountain;
  // Rute yang dipilih pada gunung tersebut
  final HikingRoute route;
  // Berat badan pendaki (diperlukan untuk estimasi waktu)
  final double bodyWeight;
  // Berat beban/ tas pendaki
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
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.5);
  LatLng? currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;

  // points loaded from JSON
  List<RoutePoint> _routePoints = [];
  int _routeStartIndex = 0;
  bool isLoading = true;

  // inference service and results
  late InferenceService _inferenceService;
  bool _isInferenceInitialized = false;
  bool _isEstimating = false;
  List<SegmentResult> _segmentResults = [];

  final GlobalKey _sheetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _sheetController.addListener(_syncSheetExtent);
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
          _routeStartIndex = _findNearestRouteStartIndex();
        });
        // ensure camera adjusts once map is visible
        if (_routePoints.isNotEmpty) {
          _fitToRoute();
        }
        if (_routePoints.isNotEmpty && _isInferenceInitialized) {
          _attemptEstimation();
        }
      }

      _locationSubscription = LocationService.getLocationStream().listen((loc) {
        if (!mounted) return;

        final newStartIndex = _findNearestRouteStartIndex(loc);
        final startIndexChanged = newStartIndex != _routeStartIndex;

        setState(() {
          currentLocation = loc;
          _routeStartIndex = newStartIndex;
        });

        if (startIndexChanged && _routePoints.isNotEmpty && _isInferenceInitialized) {
          _attemptEstimation();
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
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _saveClimbingHistory();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Inference init error: $e')));
      }
    }
  }

  Future<void> _attemptEstimation() async {
    if (!_isInferenceInitialized || _routePoints.isEmpty) return;
    if (_isEstimating) return;
    _isEstimating = true;

    try {
      _routeStartIndex = _findNearestRouteStartIndex();

      final startSegmentIndex = _routeStartIndex == 0 ? 0 : _routeStartIndex + 1;
      final rawSegments = <Map<String, dynamic>>[];

      for (int i = startSegmentIndex; i < _routePoints.length; i++) {
        final point = _routePoints[i];
        rawSegments.add({
          'delta_dist_m': point.deltaDist,
          'delta_elev_m': point.deltaElev,
          'slope_deg': point.slopeDeg,
        });
      }

      final remainingResults = rawSegments.isNotEmpty
          ? _inferenceService.processSegments(
              rawSegments,
              widget.bodyWeight,
              widget.bagWeight,
            )
          : <SegmentResult>[];

      final paddedResults = <SegmentResult>[];
      if (_routeStartIndex > 0) {
        paddedResults.addAll(
          List<SegmentResult>.generate(
            _routeStartIndex + 1,
            (_) => SegmentResult(
              label: 'Skipped',
              predicted: 0.0,
              cumulative: 0.0,
            ),
          ),
        );
      }
      paddedResults.addAll(remainingResults);

      if (mounted) {
        setState(() {
          _segmentResults = paddedResults;
        });
      }
    } catch (e) {
      debugPrint('Estimation processing failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Estimation error: $e')));
      }
    } finally {
      _isEstimating = false;
    }
  }

  Future<void> _loadRoute() async {
    List<RoutePoint> pts = [];
    try {
      // Load route using the new MountainLoader with proper path structure
      final mountainRoute = await MountainLoader.loadRoute(
        widget.mountain.id,
        widget.route.id,
      );

      if (mountainRoute != null && mountainRoute.points.isNotEmpty) {
        pts = mountainRoute.points;
        debugPrint(
          'route loader: loaded ${pts.length} points from ${widget.mountain.id}/${widget.route.id}',
        );
      } else {
        debugPrint(
          'route loader: ${widget.mountain.id}/${widget.route.id} contained no points',
        );
      }
    } catch (e, st) {
      debugPrint(
        'failed to load route ${widget.mountain.id}/${widget.route.id}: $e',
      );
      debugPrint('$st');

      // fallback to default route
      try {
        final fallbackRoute = await MountainLoader.loadRoute(
          'glonggong',
          'route_glonggong_mlaten.json',
        );
        if (fallbackRoute != null) {
          pts = fallbackRoute.points;
          debugPrint(
            'fallback loader: loaded ${pts.length} points from glonggong/route_glonggong_mlaten.json',
          );
        }
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

  void _syncSheetExtent() {
    _sheetExtent.value = _sheetController.size;
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

  int _findNearestRouteStartIndex([LatLng? location]) {
    if (location == null && currentLocation == null) return 0;
    if (_routePoints.isEmpty) return 0;

    final reference = location ?? currentLocation!;
    final distance = Distance();
    int nearestIndex = 0;
    double nearestMeters = double.infinity;

    for (int i = 0; i < _routePoints.length; i++) {
      final point = _routePoints[i];
      final d = distance.as(
        LengthUnit.Meter,
        reference,
        LatLng(point.lat, point.lon),
      );
      if (d < nearestMeters) {
        nearestMeters = d;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  void _showContactPersonDialog() {
    final contactPerson = widget.route.contactPerson;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 8, 0),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Kontak Person',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Text(
            contactPerson != null && contactPerson.isNotEmpty
                ? contactPerson
                : 'Informasi kontak tidak tersedia.',
          ),
        );
      },
    );
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (!hasGesture) return;
    _sheetController.animateTo(
      0.2,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _saveClimbingHistory() async {
    try {
      // Generate a unique ID for this history record
      const uuid = Uuid();
      final historyId = uuid.v4();

      // Create RouteSegment list from route points and segment results
      final segments = <RouteSegment>[];
      final postsWithIndex = _routePoints
          .asMap()
          .entries
          .where((e) =>
              e.key >= _routeStartIndex &&
              (e.key == _routeStartIndex ||
                  (e.value.name != null && e.value.name!.isNotEmpty)))
          .toList();

      // Add segments between consecutive waypoints (posts)
      for (int i = 0; i < postsWithIndex.length - 1; i++) {
        final fromIdx = postsWithIndex[i].key;
        final toIdx = postsWithIndex[i + 1].key;
        final fromPoint = postsWithIndex[i].value;
        final toPoint = postsWithIndex[i + 1].value;

        final fromLabel = fromIdx == _routeStartIndex && currentLocation != null
            ? 'Current Location'
            : fromPoint.name ?? 'Pos $fromIdx';
        final toLabel = toPoint.name ?? 'Pos $toIdx';

        // Calculate segment time: time to reach toIdx - time to reach fromIdx
        int segmentMinutes = 0;
        if (_segmentResults.isNotEmpty &&
            fromIdx < _segmentResults.length &&
            toIdx < _segmentResults.length) {
          final fromTime = (_segmentResults[fromIdx].cumulative / 60).round();
          final toTime = (_segmentResults[toIdx].cumulative / 60).round();
          segmentMinutes = toTime - fromTime;
        }

        segments.add(
          RouteSegment(
            from: fromLabel,
            to: toLabel,
            estimatedTime: Duration(minutes: segmentMinutes),
          ),
        );
      }

      // Add final segment to summit if there are route points and last post is not the summit
      if (postsWithIndex.isNotEmpty && _routePoints.isNotEmpty) {
        final lastPostEntry = postsWithIndex.last;
        final lastPostIdx = lastPostEntry.key;
        final lastPoint = lastPostEntry.value;
        final summitPoint = _routePoints.last;
        final summitIdx = _routePoints.length - 1;

        // Only add final segment if the last post is not already the summit
        if (lastPostIdx != summitIdx) {
          int finalSegmentMinutes = 0;
          if (_segmentResults.isNotEmpty &&
              lastPostIdx < _segmentResults.length) {
            if (summitIdx < _segmentResults.length) {
              final postTime = (_segmentResults[lastPostIdx].cumulative / 60)
                  .round();
              final summitTime = (_segmentResults[summitIdx].cumulative / 60)
                  .round();
              finalSegmentMinutes = summitTime - postTime;
            }
          }

          segments.add(
            RouteSegment(
              from: lastPoint.name ?? 'Pos ${postsWithIndex.length - 1}',
              to: summitPoint.name ?? 'Puncak',
              estimatedTime: Duration(minutes: finalSegmentMinutes),
            ),
          );
        }
      }

      // Calculate total estimated time
      Duration totalEstimatedTime = Duration.zero;
      if (_segmentResults.isNotEmpty) {
        final totalMinutes = (_segmentResults.last.cumulative / 60).round();
        totalEstimatedTime = Duration(minutes: totalMinutes);
      }

      // Create HikingHistory object
      final history = HikingHistory(
        id: historyId,
        mountainName: widget.mountain.name,
        routeName: widget.route.name,
        date: DateTime.now(),
        estimatedTime: totalEstimatedTime,
        bodyWeight: widget.bodyWeight,
        bagWeight: widget.bagWeight,
        segments: segments,
      );

      // Save to storage
      final historyService = HistoryService();
      final success = await historyService.saveHistory(history);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Riwayat pendakian berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to history page after saving
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/history',
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan riwayat pendakian'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving climbing history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _sheetController.removeListener(_syncSheetExtent);
    _sheetController.dispose();
    _sheetExtent.dispose();
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

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final bodyHeight = constraints.maxHeight;
                    return Stack(
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: LatLng(0, 0),
                            initialZoom: 13,
                            onPositionChanged: _onMapPositionChanged,
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
                          controller: _sheetController,
                          initialChildSize: 0.5,
                          minChildSize: 0.2,
                          maxChildSize: 0.85,
                          builder: (context, scrollController) {
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
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.timer_outlined,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Estimasi Waktu ke Pos',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Builder(
                                      builder: (context) {
                                        final List<MapEntry<int, RoutePoint>?>
                                        displayItems = [];
                                        if (currentLocation != null) {
                                          displayItems.add(null);
                                        }
                                        for (var e in postsWithIndex) {
                                          displayItems.add(e);
                                        }

                                        return ListView.separated(
                                          controller: scrollController,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          itemCount: displayItems.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, idx) {
                                            final item = displayItems[idx];
                                            if (item == null) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.blue.shade100,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ListTile(
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.my_location,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  title: const Text(
                                                    'Lokasi Sekarang',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  subtitle: _isEstimating
                                                      ? Row(
                                                          children: const [
                                                            SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Estimating...',
                                                            ),
                                                          ],
                                                        )
                                                      : null,
                                                  trailing:
                                                      const SizedBox.shrink(),
                                                ),
                                              );
                                            }

                                            final entry = item;
                                            final p = entry.value;
                                            final originalIdx = entry.key;
                                            int estimatedTime = 0;
                                            if (_segmentResults.isNotEmpty &&
                                                originalIdx <
                                                    _segmentResults.length) {
                                              estimatedTime =
                                                  (_segmentResults[originalIdx]
                                                              .cumulative /
                                                          60)
                                                      .round();
                                            }

                                            return Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                child: ListTile(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.green.shade50,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      p == _routePoints.last
                                                          ? Icons.flag
                                                          : Icons.house_siding,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    p.name != null &&
                                                            p.name!.isNotEmpty
                                                        ? p.name!
                                                        : 'Pos ${currentLocation != null ? idx : idx + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  subtitle: _isEstimating
                                                      ? Row(
                                                          children: const [
                                                            SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Estimating...',
                                                            ),
                                                          ],
                                                        )
                                                      : null,
                                                  trailing: Text(
                                                    'Estimasi waktu: $estimatedTime menit',
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    mapController.move(
                                                      LatLng(p.lat, p.lon),
                                                      17,
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          },
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
                          valueListenable: _sheetExtent,
                          builder: (context, extent, child) {
                            final height = bodyHeight * extent;
                            return Positioned(
                              right: 20,
                              bottom: height + 20,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.info,
                                        color: Colors.green,
                                      ),
                                      onPressed: _showContactPersonDialog,
                                    ),
                                  ),
                                  FloatingActionButton(
                                    heroTag: 'loc_main_btn',
                                    backgroundColor: Colors.green,
                                    onPressed: () {
                                      if (currentLocation != null) {
                                        mapController.move(
                                          currentLocation!,
                                          17,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
