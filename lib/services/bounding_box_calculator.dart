import 'package:latlong2/latlong.dart';
import '../models/bounding_box.dart';

/// Service untuk menghitung bounding box dari daftar titik koordinat
class BoundingBoxCalculator {
  // Faktor untuk buffer area (dalam derajat, ~500 meter pada ekuator)
  static const double bufferInDegrees = 0.0045;

  /// Menghitung bounding box dari daftar titik GPS dengan buffer area
  /// 
  /// Mengambil daftar koordinat LatLng dan menghitung:
  /// - north (latitude maksimum)
  /// - south (latitude minimum)
  /// - east (longitude maksimum)
  /// - west (longitude minimum)
  /// Kemudian menambahkan buffer ±500 meter di sekitar area
  static BoundingBox calculateBoundingBox(List<LatLng> trackPoints) {
    if (trackPoints.isEmpty) {
      throw ArgumentError('Track points cannot be empty');
    }

    // Inisialisasi dengan titik pertama
    double north = trackPoints[0].latitude;
    double south = trackPoints[0].latitude;
    double east = trackPoints[0].longitude;
    double west = trackPoints[0].longitude;

    // Iterasi melalui semua titik untuk menemukan batas-batas area
    for (final point in trackPoints) {
      if (point.latitude > north) north = point.latitude;
      if (point.latitude < south) south = point.latitude;
      if (point.longitude > east) east = point.longitude;
      if (point.longitude < west) west = point.longitude;
    }

    // Tambahkan buffer area ±500 meter
    north += bufferInDegrees;
    south -= bufferInDegrees;
    east += bufferInDegrees;
    west -= bufferInDegrees;

    return BoundingBox(
      north: north,
      south: south,
      east: east,
      west: west,
    );
  }
}
