import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/scaler_model.dart';
import 'package:flutter/foundation.dart';

/// Service for loading and managing scaler parameters from JSON file
class ScalerService {
  static final ScalerService _instance = ScalerService._internal();

  ScalerService._internal();

  factory ScalerService() {
    return _instance;
  }

  ScalerModel? _scaler;

  /// Load scaler parameters from JSON file
  /// Returns the loaded ScalerModel
  /// Throws exception if loading fails
  Future<ScalerModel> loadScaler() async {
    try {
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║         Starting Scaler Loading Process                  ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('📍 Attempting to load: assets/models/scaler_params.json');

      final jsonString = await rootBundle.loadString('assets/models/scaler_params.json');
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      _scaler = ScalerModel.fromJson(jsonMap);

      debugPrint('✅ Scaler loaded successfully!');
      debugPrint('📊 Scaler Details:');
      debugPrint('   - Mean values: ${_scaler!.mean}');
      debugPrint('   - Std values: ${_scaler!.std}');
      debugPrint('   - Number of features: ${_scaler!.mean.length}');

      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║         ✅ Scaler Loading SUCCESSFUL                     ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');

      return _scaler!;
    } catch (e) {
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║         ❌ Scaler Loading FAILED                         ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('❌ Error: $e');
      debugPrint('📝 Note: Make sure:');
      debugPrint('   1. The file exists at assets/models/scaler_params.json');
      debugPrint('   2. The file path is correctly added to pubspec.yaml');
      debugPrint('   3. The JSON format is valid with "mean" and "std" keys');
      rethrow;
    }
  }

  /// Get cached scaler model (returns null if not loaded)
  ScalerModel? getScaler() => _scaler;

  /// Check if scaler is loaded
  bool isLoaded() => _scaler != null;

  /// Perform feature scaling on input values
  /// Takes raw values and applies (value - mean) / std transformation
  List<double> scaleFeatures(List<double> rawValues) {
    if (_scaler == null) {
      throw Exception('Scaler not loaded. Call loadScaler() first.');
    }

    if (rawValues.length != _scaler!.mean.length) {
      throw Exception(
        'Input size ${rawValues.length} does not match scaler features ${_scaler!.mean.length}',
      );
    }

    return List<double>.generate(
      rawValues.length,
      (i) => (rawValues[i] - _scaler!.mean[i]) / _scaler!.std[i],
    );
  }
}
