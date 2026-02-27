class RoutePoint {
  final double lat;
  final double lon;
  final double elev;
  final double deltaDist;
  final double deltaElev;
  final double slopeDeg;
  final double cumDist;
  final String? name;

  RoutePoint({
    required this.lat,
    required this.lon,
    required this.elev,
    required this.deltaDist,
    required this.deltaElev,
    required this.slopeDeg,
    required this.cumDist,
    this.name,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    // only latitude and longitude are critical for rendering the polyline;
    // other fields may be missing in the JSON so we parse them with defaults.
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return RoutePoint(
      lat: parseDouble(json["lat"]),
      lon: parseDouble(json["lon"]),
      elev: parseDouble(json["elev"]),
      deltaDist: parseDouble(json["delta_dist_m"]),
      deltaElev: parseDouble(json["delta_elev_m"]),
      slopeDeg: parseDouble(json["slope_deg"]),
      cumDist: parseDouble(json["cum_dist_m"]),
      name: json["name"],
    );
  }
}
