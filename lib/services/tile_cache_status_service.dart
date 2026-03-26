import 'package:shared_preferences/shared_preferences.dart';

// Layanan untuk melacak status unduhan tile peta offline untuk setiap rute.
// Menggunakan SharedPreferences untuk menyimpan informasi apakah tile
// untuk rute tertentu sudah diunduh atau belum, sehingga aplikasi bisa
// menentukan apakah perlu mengunduh ulang atau menggunakan cache.
class TileCacheStatusService {
  // Prefix untuk key SharedPreferences cache status
  static const String _cachePrefix = 'tile_cache_';

  /// Menyimpan status cache untuk jalur pendakian tertentu
  /// 
  /// Menggunakan string identifier (misalnya id rute) sebagai kunci unik
  /// Status disimpan di SharedPreferences untuk persistent storage
  static Future<void> setCacheDownloaded(String routeIdentifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_cachePrefix$routeIdentifier', true);
  }

  /// Mengecek apakah tile sudah diunduh untuk jalur tertentu
  /// 
  /// Mengembalikan true jika tile sudah pernah diunduh,
  /// false jika belum diunduh atau data tidak ditemukan
  static Future<bool> isCacheDownloaded(String routeIdentifier) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_cachePrefix$routeIdentifier') ?? false;
  }

  /// Menghapus status cache untuk jalur tertentu
  /// 
  /// Berguna jika ingin memaksa re-download tile untuk jalur
  static Future<void> clearCacheStatus(String routeIdentifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$routeIdentifier');
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
