import 'route_point.dart';

/// Kelas yang merepresentasikan satu jalur pendakian pada sebuah gunung.
///
/// Berisi nama rute serta daftar titik-titik (`RoutePoint`) yang dilintasi.
class MountainRoute {
  /// Nama rute seperti tercantum di file metadata.
  final String routeName;
  /// Koleksi titik-titik yang membentuk jalur.
  final List<RoutePoint> points;

  MountainRoute({
    required this.routeName,
    required this.points,
  });

  /// Buat instance dari data JSON, biasanya dibaca dari file rute.
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

  /// Konversi kembali ke format JSON agar bisa disimpan atau dibagikan.
  Map<String, dynamic> toJson() {
    return {
      'route_name': routeName,
      'points': points.map((point) => point.toJson()).toList(),
    };
  }

  // Menghitung total panjang rute (dalam meter).
  // Jika file JSON menyediakan `cum_dist_m` pada titik terakhir, gunakan itu.
  // Bila tidak, jumlahkan semua `deltaDist` untuk mendapatkan jarak total.
  double getTotalDistance() {
    if (points.isEmpty) return 0.0;
    // lebih disukai jika nilai kumulatif terakhir tersedia
    final lastCum = points.last.cumDist;
    if (lastCum > 0) {
      return lastCum;
    }
    // jika tidak ada, hitung dari perubahan jarak
    return points.fold(0.0, (sum, p) => sum + p.deltaDist);
  }

  // Ambil daftar nama waypoint dari titik-titik yang memiliki `name`.
  List<String> getWaypoints() {
    return points.where((p) => p.name != null && p.name!.isNotEmpty).map((p) => p.name!).toList();
  }
}
