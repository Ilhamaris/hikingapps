import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/scaler_model.dart';
import 'package:flutter/foundation.dart';

// Layanan untuk memuat dan mengelola parameter scaler (rata-rata dan
// standar deviasi) dari file JSON. Scaler digunakan untuk menormalisasi
// fitur input sebelum dimasukkan ke model machine learning.
class ScalerService {
  // Singleton pattern untuk memastikan satu instance saja.
  static final ScalerService _instance = ScalerService._internal();

  ScalerService._internal();

  factory ScalerService() {
    return _instance;
  }

  // Model scaler yang disimpan dalam cache setelah dimuat.
  ScalerModel? _scaler;

  /// Memuat parameter scaler dari file JSON di assets.
  /// Mengembalikan ScalerModel yang dimuat.
  /// Melempar exception jika gagal memuat.
  Future<ScalerModel> loadScaler() async {
    try {
      debugPrint(
        '╔══════════════════════════════════════════════════════════╗',
      );
      debugPrint(
        '║         Starting Scaler Loading Process                  ║',
      );
      debugPrint(
        '╚══════════════════════════════════════════════════════════╝',
      );
      debugPrint('📍 Attempting to load: assets/models/scaler_params.json');

      // Baca file JSON sebagai string.
      final jsonString = await rootBundle.loadString(
        'assets/models/scaler_params.json',
      );
      // Parse string menjadi map.
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      // Buat objek ScalerModel dari map.
      _scaler = ScalerModel.fromJson(jsonMap);

      debugPrint('✅ Scaler loaded successfully!');
      debugPrint('📊 Scaler Details:');
      debugPrint('   - Mean values: ${_scaler!.mean}');
      debugPrint('   - Std values: ${_scaler!.std}');
      debugPrint('   - Number of features: ${_scaler!.mean.length}');
      // Additional raw debug prints for explicit parameter inspection.
      debugPrint('DEBUG: mean = ${_scaler!.mean}');
      debugPrint('DEBUG: std = ${_scaler!.std}');

      debugPrint(
        '╔══════════════════════════════════════════════════════════╗',
      );
      debugPrint('║         ✅ Scaler Loading SUCCESSFUL                     ║');
      debugPrint(
        '╚══════════════════════════════════════════════════════════╝',
      );

      return _scaler!;
    } catch (e) {
      debugPrint(
        '╔══════════════════════════════════════════════════════════╗',
      );
      debugPrint('║         ❌ Scaler Loading FAILED                         ║');
      debugPrint(
        '╚══════════════════════════════════════════════════════════╝',
      );
      debugPrint('❌ Error: $e');
      debugPrint('📝 Note: Make sure:');
      debugPrint('   1. The file exists at assets/models/scaler_params.json');
      debugPrint('   2. The file path is correctly added to pubspec.yaml');
      debugPrint('   3. The JSON format is valid with "mean" and "std" keys');
      rethrow;
    }
  }

  /// Mendapatkan model scaler yang sudah di-cache (null jika belum dimuat).
  ScalerModel? getScaler() => _scaler;

  /// Mengecek apakah scaler sudah dimuat.
  bool isLoaded() => _scaler != null;

  /// Melakukan scaling fitur pada nilai input mentah.
  /// Menggunakan transformasi (nilai - rata-rata) / standar_deviasi.
  List<double> scaleFeatures(List<double> rawValues) {
    if (_scaler == null) {
      throw Exception('Scaler not loaded. Call loadScaler() first.');
    }

    if (rawValues.length != _scaler!.mean.length) {
      throw Exception(
        'Input size ${rawValues.length} does not match scaler features ${_scaler!.mean.length}',
      );
    }

    // Hitung nilai yang sudah dinormalisasi untuk setiap fitur.
    return List<double>.generate(
      rawValues.length,
      (i) => (rawValues[i] - _scaler!.mean[i]) / _scaler!.std[i],
    );
  }
}
