import 'package:flutter/material.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import '../models/mountain_metadata.dart';
import '../services/mountain_loader.dart';
import '../widgets/route_card.dart';

// Layar untuk menampilkan daftar jalur pendakian untuk gunung yang dipilih
class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  late Future<MountainMetadata?> _metadataFuture;
  late Future<List<HikingRoute>> _routesFuture;
  Mountain? _mountain;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mountain = ModalRoute.of(context)?.settings.arguments as Mountain?;
    _metadataFuture = _mountain != null
        ? MountainLoader.loadMountainMetadata(_mountain!.id)
        : Future.value(null);
    // once metadata is available we will also prepare routes with their distances
    _routesFuture = _metadataFuture.then((metadata) {
      if (metadata == null) return <HikingRoute>[];
      return _loadRoutesFromMetadata(metadata);
    });
  }

  // helper that reads each route file and computes distance/waypoints
  Future<List<HikingRoute>> _loadRoutesFromMetadata(
    MountainMetadata metadata,
  ) async {
    final routes = <HikingRoute>[];
    if (_mountain == null) return routes;
    for (var routeInfo in metadata.routes) {
      double distanceKm = 0.0;
      List<String> waypoints = [];
      final mountainRoute = await MountainLoader.loadRoute(
        _mountain!.id,
        routeInfo.file,
      );
      if (mountainRoute != null) {
        // total distance is last point cumulative distance (in meters)
        distanceKm = mountainRoute.getTotalDistance() / 1000.0;
        waypoints = mountainRoute.getWaypoints();
      }
      routes.add(
        HikingRoute(
          id: routeInfo.file,
          name: routeInfo.name,
          distance: distanceKm,
          waypoints: waypoints,
        ),
      );
    }
    return routes;
  }

  // Membangun tampilan daftar jalur pendakian
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Pilih Jalur Pendakian',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<MountainMetadata?>(
        future: _metadataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading routes: ${snapshot.error}'),
            );
          }

          final metadata = snapshot.data;
          if (metadata == null) {
            return const Center(child: Text('No mountain metadata found'));
          }

          // We now load the actual route files to compute distances
          return FutureBuilder<List<HikingRoute>>(
            future: _routesFuture,
            builder: (context, routesSnapshot) {
              if (routesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (routesSnapshot.hasError) {
                return Center(
                  child: Text('Error loading routes: ${routesSnapshot.error}'),
                );
              }
              final routes = routesSnapshot.data ?? [];
              if (routes.isEmpty) {
                return const Center(
                  child: Text('No routes available for this mountain'),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mountain?.name ?? 'Mountain',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pilih jalur pendakian yang ingin Anda naiki:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...routes.map((route) {
                      return RouteCard(
                        route: route,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/input-parameter',
                            arguments: {'mountain': _mountain, 'route': route},
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
