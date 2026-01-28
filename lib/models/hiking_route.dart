class HikingRoute {
  final int id;
  final String name;
  final double distance;
  final String gpxFileName;
  final List<String> waypoints;

  HikingRoute({
    required this.id,
    required this.name,
    required this.distance,
    required this.gpxFileName,
    required this.waypoints,
  });
}
