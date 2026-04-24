// Kelas untuk merepresentasikan rute pendakian
class HikingRoute {
  // Identitas unik untuk rute pendakian
  final String id;
  // Nama rute pendakian
  final String name;
  // Jarak tempuh rute dalam kilometer
  final double distance;
  // Daftar titik waypoint yang dilalui dalam rute
  final List<String> waypoints;
  // Kontak person untuk rute ini.
  final String? contactPerson;

  // Konstruktor untuk menginisialisasi semua properti rute pendakian
  HikingRoute({
    required this.id,
    required this.name,
    required this.distance,
    required this.waypoints,
    this.contactPerson,
  });
}
