// Kelas untuk merepresentasikan riwayat pendakian yang telah dilakukan
class HikingHistory {
  final String id;
  final String mountainName;
  final String routeName;
  final DateTime date;
  final Duration estimatedTime;
  final double bodyWeight;
  final double bagWeight;
  final List<RouteSegment> segments;

  // Konstruktor untuk menginisialisasi semua properti riwayat pendakian
  HikingHistory({
    required this.id,
    required this.mountainName,
    required this.routeName,
    required this.date,
    required this.estimatedTime,
    required this.bodyWeight,
    required this.bagWeight,
    required this.segments,
  });
}

// Kelas untuk merepresentasikan satu segmen atau bagian dari rute pendakian
class RouteSegment {
  // Nama lokasi atau waypoint awal segmen
  final String from;
  // Nama lokasi atau waypoint akhir segmen
  final String to;
  // Waktu tempuh yang diperkirakan untuk segmen ini
  final Duration estimatedTime;

  // Konstruktor untuk menginisialisasi properti segmen rute
  RouteSegment({
    required this.from,
    required this.to,
    required this.estimatedTime,
  });
}
