// Kelas untuk merepresentasikan rute pendakian
class HikingRoute {
  // Identitas unik untuk rute pendakian
  final String id;
  // Nama rute pendakian
  final String name;
  // Jarak tempuh rute dalam kilometer
  final double distance;
  // Nama file GPX yang berisi data geografis rute
  final String gpxFileName;
  // Daftar titik waypoint yang dilalui dalam rute
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
