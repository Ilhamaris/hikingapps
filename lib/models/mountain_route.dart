import 'route_point.dart';

class MountainRoute {
  final String routeName;
  final List<RoutePoint> points;

  MountainRoute({
    required this.routeName,
    required this.points,
  });

  factory MountainRoute.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List?)
            ?.map((point) => RoutePoint.fromJson(point as Map<String, dynamic>))
            .toList() ??
        [];

    return MountainRoute(
      routeName: json['route_name'] ?? '',
      points: pointsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_name': routeName,
      'points': points.map((point) => point.toJson()).toList(),
    };
  }

  // Calculate total distance of the route (in meters)
  // JSON files don't always include `cum_dist_m`, so fall back to
  // summing the individual `deltaDist` values which correspond to the
  // `delta_dist_m` field in the raw data.
  double getTotalDistance() {
    if (points.isEmpty) return 0.0;
    // prefer last cumulative distance if it's been populated
    final lastCum = points.last.cumDist;
    if (lastCum > 0) {
      return lastCum;
    }
    // otherwise compute from deltas
    return points.fold(0.0, (sum, p) => sum + p.deltaDist);
  }

  // Get waypoint names from route
  List<String> getWaypoints() {
    return points.where((p) => p.name != null && p.name!.isNotEmpty).map((p) => p.name!).toList();
  }
}
