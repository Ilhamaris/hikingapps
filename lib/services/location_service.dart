import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Meminta izin lokasi dari pengguna
  static Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    // Mengembalikan true jika izin lokasi diberikan (saat aplikasi digunakan atau selalu)
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Mengambil lokasi pengguna saat ini
  /// Mengembalikan null jika lokasi tidak bisa didapatkan
  static Future<LatLng?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await requestLocationPermission(); // Meminta izin jika belum diberikan
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best, // Akurasi terbaik
      );

      // Mengembalikan posisi dalam bentuk LatLng
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Error saat mengambil lokasi - return null untuk menandakan gagal
      return null;
    }
  }

  /// Mendapatkan stream pembaruan lokasi secara real-time
  /// Berguna untuk pelacakan lokasi saat mendaki
  static Stream<LatLng> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10, // Update setiap 10 meter
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map((position) => LatLng(position.latitude, position.longitude)); // Mengubah posisi ke LatLng
  }
}
