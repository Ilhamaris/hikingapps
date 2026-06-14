import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _PostSegmentPlan {
  final List<Map<String, dynamic>> segments;
  final List<int> endIndices;

  _PostSegmentPlan({
    required this.segments,
    required this.endIndices,
  });
}

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

  // last location used to trigger estimation updates
  LatLng? _lastEstimationLocation;
  static const double _estimationTriggerMeters = 10.0;

  // arrival state for route waypoints
  final Map<int, DateTime> _arrivalTimes = {};
  static const double _arrivalThresholdMeters = 15.0;

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
          if (loc != null) {
            _updateArrivalTimes(loc);
          }
        });
        // ensure camera adjusts once map is visible
        if (_routePoints.isNotEmpty) {
          _fitToRoute();
        }
        if (_routePoints.isNotEmpty && _isInferenceInitialized) {
          _attemptEstimation();
          if (loc != null) {
            _lastEstimationLocation = loc;
          }
        }
      }

      _locationSubscription = LocationService.getLocationStream().listen((loc) {
        if (!mounted) return;

        final newStartIndex = _findNearestRouteStartIndex(loc);
        final startIndexChanged = newStartIndex != _routeStartIndex;

        setState(() {
          currentLocation = loc;
          _routeStartIndex = newStartIndex;
          _updateArrivalTimes(loc);
        });

        if (_routePoints.isNotEmpty && _isInferenceInitialized) {
          final bool shouldEstimate;
          if (startIndexChanged) {
            shouldEstimate = true;
          } else if (_lastEstimationLocation == null) {
            shouldEstimate = true;
          } else {
            final dist = Distance().as(
              LengthUnit.Meter,
              _lastEstimationLocation!,
              loc,
            );
            shouldEstimate = dist >= _estimationTriggerMeters;
          }

          if (shouldEstimate) {
            _lastEstimationLocation = loc;
            _attemptEstimation();
          }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(Icons.flag_circle_rounded, size: 44, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Selesai Mendaki?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Data perjalanan akan disimpan ke riwayat. Akhiri pendakian sekarang?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
              ),
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
      // Build plan using every adjacent route segment, then accumulate per post.
      final plan = _buildAllSegmentPlan();
      debugPrint('🧠 Full-route estimation plan: ${plan.endIndices.length} segments');
      for (int i = 0; i < plan.endIndices.length; i++) {
        final endIndex = plan.endIndices[i];
        final startIndex = i == 0 ? 0 : plan.endIndices[i - 1];
        final startName = _routePoints[startIndex].name ?? 'Pos $startIndex';
        final endName = _routePoints[endIndex].name ?? 'Pos $endIndex';
        debugPrint('   • Segment ${i + 1}: $startName ($startIndex) → $endName ($endIndex)');
        debugPrint('     raw features: ${plan.segments[i]}');
      }

      final remainingResults = plan.segments.isNotEmpty
          ? _inferenceService.processSegments(
              plan.segments,
              widget.bodyWeight,
              widget.bagWeight,
            )
          : <SegmentResult>[];

      final paddedResults = List<SegmentResult>.generate(
        _routePoints.length,
        (_) => SegmentResult(
          label: 'Skipped',
          predicted: 0.0,
          cumulative: 0.0,
        ),
      );

      for (int i = 0; i < remainingResults.length; i++) {
        final endIndex = plan.endIndices[i];
        final result = remainingResults[i];
        paddedResults[endIndex] = SegmentResult(
          label: _routePoints[endIndex].name ?? 'Pos $endIndex',
          predicted: result.predicted,
          cumulative: result.cumulative,
        );
      }

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

  

  Map<String, dynamic>? _aggregateSegmentFeatures(
    int startIndex,
    int endIndex,
  ) {
    if (startIndex >= endIndex) return null;

    double totalDist = 0.0;
    double totalElev = 0.0;
    double weightedSlopeSum = 0.0;

    for (int i = startIndex + 1; i <= endIndex; i++) {
      final point = _routePoints[i];
      totalDist += point.deltaDist;
      totalElev += point.deltaElev;
      weightedSlopeSum += point.slopeDeg * point.deltaDist;
    }

    if (totalDist <= 0.0) return null;

    final averageSlope = weightedSlopeSum / totalDist;
    return {
      'delta_dist_m': totalDist,
      'delta_elev_m': totalElev,
      'slope_deg': averageSlope,
    };
  }

  // Build a plan using every adjacent route segment from start to end.
  _PostSegmentPlan _buildAllSegmentPlan() {
    final totalPoints = _routePoints.length;
    if (totalPoints <= 1) return _PostSegmentPlan(segments: [], endIndices: []);

    final segments = <Map<String, dynamic>>[];
    final endIndices = <int>[];

    for (int i = 1; i < totalPoints; i++) {
      final aggregated = _aggregateSegmentFeatures(i - 1, i);
      if (aggregated != null) {
        segments.add(aggregated);
        endIndices.add(i);
      }
    }

    return _PostSegmentPlan(segments: segments, endIndices: endIndices);
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
          // route points loaded
        if (currentLocation != null) {
          _updateArrivalTimes(currentLocation!);
        }
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

  void _updateArrivalTimes(LatLng location) {
    if (_routePoints.isEmpty) return;
    final distance = Distance();
    for (int i = 0; i < _routePoints.length; i++) {
      if (_arrivalTimes.containsKey(i)) continue;
      final point = _routePoints[i];
      if (point.name == null || point.name!.isEmpty) continue;
      final meters = distance.as(
        LengthUnit.Meter,
        location,
        LatLng(point.lat, point.lon),
      );
      if (meters <= _arrivalThresholdMeters) {
        _arrivalTimes[i] = DateTime.now();
      }
    }
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

  String _formatDurationString(int totalMinutes) {
    if (totalMinutes <= 0) {
      return '0 menit';
    }
    final duration = Duration(minutes: totalMinutes);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return minutes > 0
          ? '$hours jam $minutes menit'
          : '$hours jam';
    }
    return '$minutes menit';
  }

  void _showContactPersonDialog() {
    final contactPerson = widget.route.contactPerson;
    final hasContact = contactPerson != null && contactPerson.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 8, 0),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green.shade700.withValues(alpha: 0.16),
                child: Icon(
                  Icons.contact_emergency_outlined,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kontak Darurat',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.route.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasContact
                          ? contactPerson
                          : 'Informasi kontak tidak tersedia.',
                      style: TextStyle(
                        fontSize: 16,
                        color: hasContact
                            ? Colors.grey[800]
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasContact)
                    IconButton(
                      splashRadius: 22,
                      splashColor: Colors.green.shade700.withValues(
                        alpha: 0.18,
                      ),
                      highlightColor: Colors.green.shade700.withValues(
                        alpha: 0.08,
                      ),
                      padding: const EdgeInsets.all(8),
                      icon: Icon(Icons.copy, color: Colors.green.shade700),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: contactPerson));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nomor telah disalin')),
                        );
                      },
                      tooltip: 'Salin nomor',
                    ),
                ],
              ),
            ],
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
          .where(
            (e) =>
                e.key >= _routeStartIndex &&
                (e.key == _routeStartIndex ||
                    (e.value.name != null && e.value.name!.isNotEmpty)),
          )
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

      final reachedWaypoints = _routePoints
          .asMap()
          .entries
          .where(
            (e) =>
                _arrivalTimes.containsKey(e.key) &&
                e.value.name != null &&
                e.value.name!.isNotEmpty,
          )
          .map(
            (e) => WaypointHistory(
              name: e.value.name ?? 'Pos ${e.key}',
              isStart: e.key == 0,
              time: _arrivalTimes[e.key]!,
            ),
          )
          .toList();

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
        waypoints: reachedWaypoints,
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
                                        final displayItems = postsWithIndex;

                                        final showRouteEstimate =
                                            currentLocation != null &&
                                            _routePoints.isNotEmpty;

                                        if (!showRouteEstimate) {
                                          return ListView(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            children: [
                                              Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Text(
                                                    currentLocation == null
                                                        ? 'Lokasi tidak tersedia. Pastikan izin lokasi diberikan.'
                                                        : 'Estimasi tidak tersedia. Memuat data jalur...',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
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
                                            final entry = displayItems[idx];
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

                                            final hasArrival = _arrivalTimes
                                                .containsKey(originalIdx);
                                            final arrivalTime =
                                                _arrivalTimes[originalIdx];
                                            final trailingText =
                                                hasArrival &&
                                                        arrivalTime != null
                                                    ? originalIdx == 0
                                                        ? "Berangkat pukul: ${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')} WIB"
                                                        : "Tiba pukul: ${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')} WIB"
                                                    :
                                                        'Estimasi waktu: ${_formatDurationString(estimatedTime)}';

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
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (_isEstimating)
                                                        Row(
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
                                                        ),
                                                      Text(
                                                        trailingText,
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
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
