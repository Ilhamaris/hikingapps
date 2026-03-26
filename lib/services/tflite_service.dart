import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

// Layanan untuk mengelola model TensorFlow Lite, termasuk memuat model,
// menjalankan inferensi, dan membersihkan sumber daya. Model digunakan
// untuk memprediksi waktu pendakian berdasarkan fitur input.
class TFLiteService {
  // Singleton pattern untuk memastikan hanya satu instance interpreter.
  static final TFLiteService _instance = TFLiteService._internal();

  TFLiteService._internal();

  factory TFLiteService() {
    return _instance;
  }

  // Interpreter TFLite untuk menjalankan model.
  tflite.Interpreter? _interpreter;
  // Flag untuk menandai apakah model sudah dimuat.
  bool _isInitialized = false;

  /// Memuat model TFLite dari folder assets aplikasi.
  /// Menginisialisasi interpreter dan mengalokasikan tensor.
  Future<void> loadModel() async {
    try {
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║       Starting TFLite Model Loading Process              ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('📍 Attempting to load: assets/models/linear_regression.tflite');

      // Muat model dari assets.
      _interpreter = await tflite.Interpreter.fromAsset(
        'assets/models/linear_regression.tflite',
      );

      if (_interpreter != null) {
        // Alokasikan tensor untuk performa yang lebih baik.
        _interpreter!.allocateTensors();

        debugPrint('✅ Model loaded successfully!');
        debugPrint('📊 Model Details:');
        debugPrint('   - Input tensors: ${_interpreter!.getInputTensors().length}');
        debugPrint('   - Output tensors: ${_interpreter!.getOutputTensors().length}');

        // Tampilkan detail tensor input.
        for (int i = 0; i < _interpreter!.getInputTensors().length; i++) {
          final tensor = _interpreter!.getInputTensors()[i];
          debugPrint('   - Input $i: shape=${tensor.shape}, dtype=${tensor.type}');
        }

        // Tampilkan detail tensor output.
        for (int i = 0; i < _interpreter!.getOutputTensors().length; i++) {
          final tensor = _interpreter!.getOutputTensors()[i];
          debugPrint('   - Output $i: shape=${tensor.shape}, dtype=${tensor.type}');
        }

        _isInitialized = true;

        debugPrint('╔══════════════════════════════════════════════════════════╗');
        debugPrint('║       ✅ TFLite Model Loading SUCCESSFUL                ║');
        debugPrint('╚══════════════════════════════════════════════════════════╝');
      } else {
        throw Exception('Failed to initialize interpreter');
      }
    } catch (e) {
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║       ❌ TFLite Model Loading FAILED                     ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('❌ Error: $e');
      debugPrint('📝 Note: Make sure:');
      debugPrint('   1. The file exists at assets/models/linear_regression.tflite');
      debugPrint('   2. The file path is correctly added to pubspec.yaml');
      debugPrint('   3. Run: flutter pub get && flutter pub upgrade');
      debugPrint('   4. The .tflite file is a valid TensorFlow Lite model');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Mengecek apakah model sudah diinisialisasi.
  bool isInitialized() => _isInitialized;

  /// Menjalankan inferensi pada data input.
  /// Input: Daftar 5 fitur yang sudah diskalakan [berat_badan, berat_beban, delta_jarak, delta_elevasi, kemiringan].
  /// Output: Nilai prediksi sebagai double (waktu dalam detik atau menit).
  double runInference(List<double> input) {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized. Call loadModel() first.');
    }

    if (input.length != 5) {
      throw Exception('Input must contain exactly 5 features, got ${input.length}');
    }

    try {
      // Siapkan input dalam bentuk yang benar [1, 5] (batch size 1).
      final inputData = [input];

      // Tentukan bentuk output secara dinamis dan alokasikan buffer.
      // Banyak model regresi sederhana menghasilkan bentuk [1, 1].
      final outTensor = _interpreter!.getOutputTensors().first;
      final shape = outTensor.shape;

      late dynamic outputBuffer;
      if (shape.length == 2) {
        // Misal [1,1] -> [[0.0]]
        outputBuffer = List.generate(
          shape[0],
          (_) => List<double>.filled(shape[1], 0.0),
        );
      } else if (shape.length == 1) {
        outputBuffer = List<double>.filled(shape[0], 0.0);
      } else {
        // Fallback ke buffer datar.
        outputBuffer = List<double>.filled(shape.reduce((a, b) => a * b), 0.0);
      }

      // Jalankan inferensi; menggunakan run() menangani input tunggal dan jamak.
      _interpreter!.run(inputData, outputBuffer);

      // Ekstrak prediksi dari buffer secara generik.
      double prediction;
      if (outputBuffer is List<List<double>>) {
        prediction = outputBuffer.isNotEmpty && outputBuffer[0].isNotEmpty
            ? outputBuffer[0][0]
            : 0.0;
      } else if (outputBuffer is List<double>) {
        prediction = outputBuffer.isNotEmpty ? outputBuffer[0] : 0.0;
      } else {
        prediction = 0.0;
      }

      return prediction;
    } catch (e) {
      debugPrint('❌ Inference error: $e');
      rethrow;
    }
  }

  /// Menutup interpreter dan melepaskan sumber daya.
  void close() {
    if (_interpreter != null) {
      _interpreter!.close();
      _isInitialized = false;
      debugPrint('🔌 TFLite interpreter closed and resources released');
    }
  }
}
