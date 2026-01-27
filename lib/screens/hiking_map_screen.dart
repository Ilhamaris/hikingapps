import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/hiking_route.dart';
import '../services/gpx_service.dart';
import '../services/location_service.dart';
import '../widgets/bottom_sheet_estimation.dart';

class HikingMapScreen extends StatefulWidget {
  const HikingMapScreen({super.key});

  @override
  State<HikingMapScreen> createState() => _HikingMapScreenState();
}

// Kelas State untuk mengelola status layar peta pendakian
class _HikingMapScreenState extends State<HikingMapScreen> {
  // Pengontrol untuk mengelola peta interaktif
  late MapController _mapController;
  // Daftar titik-titik GPS yang membentuk jalur pendakian
  List<LatLng> _trackPoints = [];
  // Pemetaan nama lokasi ke koordinat waypoint
  Map<String, LatLng> _waypoints = {};
  // Lokasi pengguna saat ini dari GPS
  LatLng? _userLocation;
  // Status apakah peta sedang dimuat
  bool _isLoadingMap = true;

  // Menginisialisasi state widget saat pertama kali dibuat
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  // Fungsi untuk memuat data peta, jalur GPX, dan lokasi pengguna
  Future<void> _initializeMap() async {
    // Mengambil argumen rute dari parameter navigasi
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final route = args?['route'] as HikingRoute?;

    // Memastikan rute sudah dipilih sebelum memuat data
    if (route != null) {
      // Mengambil lokasi pengguna saat ini dari layanan GPS
      final userLocation = await LocationService.getCurrentLocation();
      
      // Memuat jalur trek dari file GPX
      final trackPoints =
          await GPXService.loadGPXTrack(route.gpxFileName);
      // Memuat semua waypoint (titik orientasi) dari file GPX
      final waypoints =
          await GPXService.loadGPXWaypoints(route.gpxFileName);

      // Memperbarui state dengan data yang sudah dimuat
      setState(() {
        _trackPoints = trackPoints;
        _waypoints = waypoints;
        _userLocation = userLocation;
        _isLoadingMap = false; // Tandai selesai loading
      });

      // Pusatkan tampilan peta ke lokasi pengguna
      if (userLocation != null) {
        // Pindahkan peta ke lokasi pengguna dengan level zoom 15
        _mapController.move(
          userLocation,
          15,
        );
      } else if (_trackPoints.isNotEmpty) {
        // Jika tidak bisa mendapat lokasi pengguna, gunakan titik awal jalur
        _mapController.move(
          _trackPoints[0],
          15,
        );
      }
    } else {
      // Jika rute tidak ditemukan, hentikan loading dan tampilkan error
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  // Membersihkan sumber daya saat widget dihapus
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final route = args?['route'] as HikingRoute?;

    if (_isLoadingMap) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text('Peta Pendakian'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Jika rute tidak ditemukan, tampilkan pesan error
    if (route == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text('Peta Pendakian'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Rute tidak ditemukan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: Text(
          route.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Map - expanded to fill available space
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation ??
                    (_trackPoints.isNotEmpty
                        ? _trackPoints[0]
                        : const LatLng(-6.9271, 107.7085)), // Default to Java
                initialZoom: 15,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                // Draw GPX track as polyline
                if (_trackPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _trackPoints,
                        strokeWidth: 4,
                        color: Colors.green,
                      ),
                    ],
                  ),
                // Draw waypoints as markers
                MarkerLayer(
                markers: [
                  ..._waypoints.entries.map((entry) {
                    return Marker(
                      point: entry.value,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(entry.key),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }),
                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            ),
          ),
          // Floating Action Buttons
          Positioned(
            bottom: 120,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'center',
                  backgroundColor: Colors.green,
                  onPressed: () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 15);
                    } else if (_trackPoints.isNotEmpty) {
                      _mapController.move(_trackPoints[0], 15);
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'compass',
                  backgroundColor: Colors.green,
                  onPressed: () {
                    // Compass functionality (UI only)
                  },
                  child: const Icon(Icons.explore),
                ),
              ],
            ),
          ),
          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomSheetEstimation(
              segments: [
                EstimationSegment(
                  location: 'Pos 1 Cibodas',
                  hours: 1,
                  minutes: 45,
                ),
                EstimationSegment(
                  location: 'Pos 2 Cibodas',
                  hours: 2,
                  minutes: 10,
                ),
                EstimationSegment(
                  location: 'Pos 3 Kandang Batu',
                  hours: 1,
                  minutes: 25,
                ),
                EstimationSegment(
                  location: 'Puncak Gunung',
                  hours: 1,
                  minutes: 10,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Selesaikan Pendakian?'),
              content: const Text(
                'Pendakian masih berlangsung. Jika Anda keluar sekarang, sistem akan mencatat pendakian sebagai selesai dan menyimpan data waktu tempuh.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pendakian berhasil disimpan'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Selesaikan Pendakian'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
