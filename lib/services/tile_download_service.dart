import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import '../models/bounding_box.dart';

/// Service untuk mengunduh tile peta offline berdasarkan area geografis
class TileDownloadService {
  // URL template untuk tile dari OpenStreetMap
  static const String _tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Mengunduh tile untuk area tertentu berdasarkan bounding box
  /// 
  /// Fungsi ini:
  /// - Mengunduh tile berdasarkan koordinat bounding box
  /// - Menggunakan zoom level 14-16 untuk keseimbangan detail dan ukuran
  /// - Menyimpan tile ke cache storage yang sudah diinisialisasi
  /// - Hanya dijalankan sekali setelah user memilih jalur pendakian
  static Future<void> downloadTilesForRoute(
    BoundingBox boundingBox, {
    Function(double)? onProgress,
  }) async {
    try {
      // Dapatkan cache store yang sudah diinisialisasi
      final store = FMTCStore('default');

      // Definisikan rentang zoom untuk download
      const int minZoom = 14;
      const int maxZoom = 16;

      // Konfigurasi region untuk download
      final region = CustomPolygonRegion(
        [
          LatLng(boundingBox.north, boundingBox.west), // NW
          LatLng(boundingBox.north, boundingBox.east), // NE
          LatLng(boundingBox.south, boundingBox.east), // SE
          LatLng(boundingBox.south, boundingBox.west), // SW
        ],
      );

      // Mulai download tile dengan tile provider OpenStreetMap
      await store.download(
        urls: [_tileUrlTemplate],
        region: region,
        minZoom: minZoom,
        maxZoom: maxZoom,
        onProgress: (progress) {
          // Panggil callback progress jika disediakan
          onProgress?.call(progress.percentageComplete);
        },
      );
    } catch (e) {
      throw Exception('Gagal mengunduh tile: $e');
    }
  }

  /// Mendapatkan statistik ukuran cache
  static Future<int> getCacheSize() async {
    try {
      final store = FMTCStore('default');

      final stats = await store.stats();
      return stats.cacheSize;
    } catch (e) {
      return 0;
    }
  }
}
