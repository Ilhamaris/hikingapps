import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../models/hiking_history.dart';
import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class HistoryService {
  /// Get all histories from SQLite. On first access, migrate SharedPreferences.
  Future<List<HikingHistory>> getAllHistories() async {
    try {
      await DatabaseService.instance.migrateFromSharedPreferences();
      final db = await DatabaseService.instance.database;
      final rows = await db.query('histories', orderBy: 'date DESC');
      return rows.map((row) {
        final data = row['data'] as String?;
        if (data == null || data.isEmpty) return null;
        final map = jsonDecode(data) as Map<String, dynamic>;
        return HikingHistory.fromJson(map);
      }).whereType<HikingHistory>().toList();
    } catch (e) {
      debugPrint('Error loading histories from DB: $e');
      return [];
    }
  }

  Future<bool> saveHistory(HikingHistory history) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.insert(
        'histories',
        {
          'id': history.id,
          'mountainName': history.mountainName,
          'routeName': history.routeName,
          'date': history.date.toIso8601String(),
          'data': jsonEncode(history.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Error saving history to DB: $e');
      return false;
    }
  }

  Future<bool> deleteHistory(String id) async {
    try {
      final db = await DatabaseService.instance.database;
      final count = await db.delete('histories', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      debugPrint('Error deleting history from DB: $e');
      return false;
    }
  }

  Future<HikingHistory?> getHistory(String id) async {
    try {
      final db = await DatabaseService.instance.database;
      final rows = await db.query('histories', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return null;
      final data = rows.first['data'] as String?;
      if (data == null || data.isEmpty) return null;
      final map = jsonDecode(data) as Map<String, dynamic>;
      return HikingHistory.fromJson(map);
    } catch (e) {
      debugPrint('Error getting history from DB: $e');
      return null;
    }
  }

  Future<bool> clearAllHistories() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('histories');
      return true;
    } catch (e) {
      debugPrint('Error clearing histories in DB: $e');
      return false;
    }
  }
}
