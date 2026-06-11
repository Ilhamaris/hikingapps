import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Simple SQLite wrapper for the app.
class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'hikingapps.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE histories (
            id TEXT PRIMARY KEY,
            mountainName TEXT,
            routeName TEXT,
            date TEXT,
            data TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE tile_cache (
            routeIdentifier TEXT PRIMARY KEY,
            downloaded INTEGER
          )
        ''');
      },
    );
  }

  /// Migrate existing SharedPreferences data into SQLite where applicable.
  /// This is safe to call multiple times; migration checks presence first.
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate histories key if present
    const historiesKey = 'hiking_histories';
    final jsonString = prefs.getString(historiesKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final db = await database;
        final List<dynamic> jsonList = jsonDecode(jsonString);
        for (final item in jsonList) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          await db.insert(
            'histories',
            {
              'id': id,
              'mountainName': map['mountainName'] ?? '',
              'routeName': map['routeName'] ?? '',
              'date': map['date'] ?? DateTime.now().toIso8601String(),
              'data': jsonEncode(map),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        // remove old key after migration
        await prefs.remove(historiesKey);
      } catch (e) {
        // ignore migration errors
      }
    }

    // Migrate tile cache flags
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('tile_cache_')) {
        final routeId = key.substring('tile_cache_'.length);
        final downloaded = prefs.getBool(key) ?? false;
        final db = await database;
        await db.insert(
          'tile_cache',
          {
            'routeIdentifier': routeId,
            'downloaded': downloaded ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await prefs.remove(key);
      }
    }
  }
}
