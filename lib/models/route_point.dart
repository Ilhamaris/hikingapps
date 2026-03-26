/// Model yang merepresentasikan satu titik dalam rute pendakian.
///
/// Titik ini berisi informasi geografis dan perubahan yang terjadi
/// sejak titik sebelumnya (delta distance / elevation) serta nama opsional
/// jika titik tersebut merupakan waypoint penting.
class RoutePoint {
  /// Latitude titik (derajat).
  final double lat;
  /// Longitude titik (derajat).
  final double lon;
  /// Elevasi titik dalam meter.
  final double elev;
  /// Jarak dari titik sebelumnya dalam meter.
  final double deltaDist;
  /// Perubahan elevasi dari titik sebelumnya dalam meter.
  final double deltaElev;
  /// Kemiringan (slope) dalam derajat antara titik sebelumnya dan ini.
  final double slopeDeg;
  /// Jarak kumulatif dari awal rute hingga titik ini (meter).
  final double cumDist;
  /// Nama opsional (misal "pos 1", "puncak").
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
    // latitude dan longitude minimal untuk menggambar garis pada peta.
    // field lain mungkin tidak ada di JSON, jadi kita parsing dengan nilai
    // default 0.0 agar tidak terjadi null error.
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

  /// Mengubah objek menjadi map JSON sesuai format yang digunakan oleh
  /// file rute (misalnya untuk disimpan atau dikirimkan).
  Map<String, dynamic> toJson() {
    return {
      "lat": lat,
      "lon": lon,
      "elev": elev,
      "delta_dist_m": deltaDist,
      "delta_elev_m": deltaElev,
      "slope_deg": slopeDeg,
      "cum_dist_m": cumDist,
      "name": name,
    };
  }
}
