import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/hiking_history.dart';

class HistoryService {
  static const String _storageKey = 'hiking_histories';

  /// Get all saved hiking histories
  Future<List<HikingHistory>> getAllHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => HikingHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading histories: $e');
      return [];
    }
  }

  /// Save a new hiking history
  Future<bool> saveHistory(HikingHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = await getAllHistories();

      // Add the new history at the beginning (newest first)
      histories.insert(0, history);

      // Convert to JSON list and save
      final jsonList =
          histories.map((history) => history.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving history: $e');
      return false;
    }
  }

  /// Delete a hiking history by ID
  Future<bool> deleteHistory(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = await getAllHistories();

      // Remove the history with matching ID
      histories.removeWhere((history) => history.id == id);

      // Save updated list
      final jsonList =
          histories.map((history) => history.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error deleting history: $e');
      return false;
    }
  }

  /// Get a specific history by ID
  Future<HikingHistory?> getHistory(String id) async {
    try {
      final histories = await getAllHistories();
      for (final history in histories) {
        if (history.id == id) {
          return history;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting history: $e');
      return null;
    }
  }

  /// Clear all histories (use with caution!)
  Future<bool> clearAllHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing histories: $e');
      return false;
    }
  }
}
