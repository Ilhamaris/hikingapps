import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/hiking_history.dart';

// Menggunakan SharedPreferences untuk menyimpan data secara lokal di perangkat.
class HistoryService {
  // Semua data riwayat disimpan dalam satu string JSON.
  static const String _storageKey = 'hiking_histories';

  /// Mengambil semua riwayat pendakian yang tersimpan.
  /// Mengembalikan daftar kosong jika tidak ada data atau terjadi error.
  Future<List<HikingHistory>> getAllHistories() async {
    try {
      // Mengakses penyimpanan lokal perangkat.
      final prefs = await SharedPreferences.getInstance();
      // Mengambil string JSON yang menyimpan semua riwayat.
      final jsonString = prefs.getString(_storageKey);

      // Jika tidak ada data, kembalikan daftar kosong.
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      // Mengubah string JSON menjadi daftar objek dinamis.
      final List<dynamic> jsonList = jsonDecode(jsonString);
      // Mengubah setiap objek JSON menjadi objek HikingHistory.
      return jsonList
          .map((json) => HikingHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Mencetak error untuk debugging, tapi tetap kembalikan daftar kosong.
      debugPrint('Error loading histories: $e');
      return [];
    }
  }

  /// Menyimpan riwayat pendakian baru ke penyimpanan.
  /// Riwayat baru ditambahkan di awal daftar (terbaru di atas).
  Future<bool> saveHistory(HikingHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Ambil semua riwayat yang ada terlebih dahulu.
      final histories = await getAllHistories();

      // Tambahkan riwayat baru di posisi pertama.
      histories.insert(0, history);

      // Ubah daftar riwayat menjadi daftar JSON.
      final jsonList =
          histories.map((history) => history.toJson()).toList();
      // Ubah daftar JSON menjadi string untuk disimpan.
      final jsonString = jsonEncode(jsonList);

      // Simpan string JSON ke penyimpanan.
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving history: $e');
      return false; // Gagal menyimpan.
    }
  }

  /// Menghapus riwayat pendakian berdasarkan ID.
  /// Mencari dan menghapus riwayat yang cocok, lalu menyimpan ulang.
  Future<bool> deleteHistory(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = await getAllHistories();

      // Hapus riwayat yang ID-nya cocok.
      histories.removeWhere((history) => history.id == id);

      // Simpan daftar yang sudah diperbarui.
      final jsonList =
          histories.map((history) => history.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error deleting history: $e');
      return false;
    }
  }

  /// Mengambil riwayat pendakian tertentu berdasarkan ID.
  /// Mengembalikan null jika tidak ditemukan.
  Future<HikingHistory?> getHistory(String id) async {
    try {
      final histories = await getAllHistories();
      // Cari riwayat dengan ID yang cocok.
      for (final history in histories) {
        if (history.id == id) {
          return history;
        }
      }
      return null; // Tidak ditemukan.
    } catch (e) {
      debugPrint('Error getting history: $e');
      return null;
    }
  }

  /// Menghapus semua riwayat pendakian (gunakan dengan hati-hati!).
  /// Menghapus seluruh data riwayat dari penyimpanan.
  Future<bool> clearAllHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Hapus data dengan kunci tertentu.
      return await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing histories: $e');
      return false;
    }
  }
}
