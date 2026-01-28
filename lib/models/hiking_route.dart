// Kelas untuk merepresentasikan rute pendakian
class HikingRoute {
  final String id;
  final String name;
  final double distance;
  final String gpxFileName;
  final List<String> waypoints;

  // Konstruktor untuk menginisialisasi semua properti rute pendakian
  HikingRoute({
    required this.id,
    required this.name,
    required this.distance,
    required this.gpxFileName,
    required this.waypoints,
  });
}
