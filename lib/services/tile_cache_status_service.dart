import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class TileCacheStatusService {
  /// Mark route tiles as downloaded (migrates prefs first).
  static Future<void> setCacheDownloaded(String routeIdentifier) async {
    await DatabaseService.instance.migrateFromSharedPreferences();
    final db = await DatabaseService.instance.database;
    await db.insert(
      'tile_cache',
      {'routeIdentifier': routeIdentifier, 'downloaded': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Check if tiles downloaded for route
  static Future<bool> isCacheDownloaded(String routeIdentifier) async {
    await DatabaseService.instance.migrateFromSharedPreferences();
    final db = await DatabaseService.instance.database;
    final rows = await db.query('tile_cache', where: 'routeIdentifier = ?', whereArgs: [routeIdentifier]);
    if (rows.isEmpty) return false;
    final downloaded = rows.first['downloaded'] as int?;
    return (downloaded ?? 0) == 1;
  }

  static Future<void> clearCacheStatus(String routeIdentifier) async {
    final db = await DatabaseService.instance.database;
    await db.delete('tile_cache', where: 'routeIdentifier = ?', whereArgs: [routeIdentifier]);
  }

  static Future<void> clearAllCacheStatus() async {
    final db = await DatabaseService.instance.database;
    await db.delete('tile_cache');
  }
}
