  class HikingHistory {
  final int id;
  final String mountainName;
  final String routeName;
  final DateTime date;
  final Duration estimatedTime;
  final double bodyWeight;
  final double bagWeight;
  final List<RouteSegment> segments;

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

class RouteSegment {
  final String from;
  final String to;
  final Duration estimatedTime;

  RouteSegment({
    required this.from,
    required this.to,
    required this.estimatedTime,
  });
}
