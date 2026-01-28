// Kelas riwayat pendakian 
  class HikingHistory {
  final int id;
  final String mountainName;
  final String routeName;
  final DateTime date;
  final Duration estimatedTime;
  final double bodyWeight;
  final double bagWeight;
  final List<RouteSegment> segments;

  // menginisialisasi objek riwayat pendakian
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

// merepresentasikan satu segmen atau bagian dari rute pendakian
class RouteSegment {
  final String from;
  final String to;
  final Duration estimatedTime;

  // menginisialisasi objek segmen rute
  RouteSegment({
    required this.from,
    required this.to,
    required this.estimatedTime,
  });
}
