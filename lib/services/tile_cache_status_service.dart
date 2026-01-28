import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola status cache tile untuk setiap jalur pendakian
class TileCacheStatusService {
  // Prefix untuk key SharedPreferences cache status
  static const String _cachePrefix = 'tile_cache_';

  /// Menyimpan status cache untuk jalur pendakian tertentu
  /// 
  /// Menggunakan nama file GPX sebagai identifier unik untuk jalur
  /// Status disimpan di SharedPreferences untuk persistent storage
  static Future<void> setCacheDownloaded(String gpxFileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_cachePrefix$gpxFileName', true);
  }

  /// Mengecek apakah tile sudah diunduh untuk jalur tertentu
  /// 
  /// Mengembalikan true jika tile sudah pernah diunduh,
  /// false jika belum diunduh atau data tidak ditemukan
  static Future<bool> isCacheDownloaded(String gpxFileName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_cachePrefix$gpxFileName') ?? false;
  }

  /// Menghapus status cache untuk jalur tertentu
  /// 
  /// Berguna jika ingin memaksa re-download tile untuk jalur
  static Future<void> clearCacheStatus(String gpxFileName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$gpxFileName');
  }

  /// Menghapus semua status cache
  static Future<void> clearAllCacheStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
