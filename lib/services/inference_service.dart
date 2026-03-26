import 'package:flutter/foundation.dart';
import '../models/segment_result.dart';
import 'scaler_service.dart';
import 'tflite_service.dart';

// Layanan utama untuk memproses data segmen jalur dan menjalankan
// inferensi menggunakan model machine learning. Menggabungkan
// preprocessing (scaling) dan prediksi waktu pendakian.
class InferenceService {
  // Singleton pattern: hanya satu instance yang digunakan di seluruh app.
  static final InferenceService _instance = InferenceService._internal();

  InferenceService._internal();

  factory InferenceService() {
    return _instance;
  }

  // Layanan untuk menormalisasi fitur input.
  final ScalerService _scalerService = ScalerService();
  // Layanan untuk menjalankan model TensorFlow Lite.
  final TFLiteService _tfliteService = TFLiteService();

  /// Memproses satu segmen data menjadi fitur yang sudah dinormalisasi.
  /// Mengambil 5 fitur wajib dalam urutan tertentu:
  /// 1. berat badan, 2. berat beban, 3. jarak delta (m), 4. elevasi delta (m), 5. kemiringan (derajat).
  /// Mengembalikan daftar fitur yang sudah diskalakan.
  List<double> preprocessSegment(
    Map<String, dynamic> segmentData,
    double bodyWeight,
    double loadWeight,
  ) {
    try {
      // Ekstrak fitur dari data segmen.
      final deltaDistM = (segmentData['delta_dist_m'] as num).toDouble();
      final deltaElevM = (segmentData['delta_elev_m'] as num).toDouble();
      final slopeDeg = (segmentData['slope_deg'] as num).toDouble();

      // Gabungkan semua fitur dalam urutan yang benar.
      final rawFeatures = [bodyWeight, loadWeight, deltaDistM, deltaElevM, slopeDeg];

      // Normalisasi fitur menggunakan scaler.
      final scaledFeatures = _scalerService.scaleFeatures(rawFeatures);

      debugPrint('📐 Preprocessed Segment:');
      debugPrint('   - Raw features: $rawFeatures');
      debugPrint('   - Scaled features: $scaledFeatures');

      return scaledFeatures;
    } catch (e) {
      debugPrint('❌ Preprocessing error: $e');
      rethrow; // Lempar ulang error agar ditangani di atas.
    }
  }

  /// Memproses beberapa segmen sekaligus dengan perhitungan kumulatif.
  /// Membutuhkan berat badan dan beban dari input pengguna.
  /// Mengembalikan daftar hasil segmen dengan prediksi dan total kumulatif.
  List<SegmentResult> processSegments(
    List<Map<String, dynamic>> rawSegments,
    double bodyWeight,
    double loadWeight,
  ) {
    try {
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║       Starting Batch Segment Processing                  ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('📊 Processing ${rawSegments.length} segments...');
      debugPrint('   - Body Weight: $bodyWeight kg');
      debugPrint('   - Load Weight: $loadWeight kg\n');

      final results = <SegmentResult>[];
      double cumulativeSum = 0.0; // Total waktu kumulatif.

      for (int i = 0; i < rawSegments.length; i++) {
        final segment = rawSegments[i];

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🔄 Processing Segment ${i + 1}/${rawSegments.length}');

        // Preproses segmen ini.
        final scaledFeatures = preprocessSegment(segment, bodyWeight, loadWeight);

        // Jalankan inferensi untuk mendapatkan prediksi waktu.
        final prediction = _tfliteService.runInference(scaledFeatures);

        // Tambahkan ke total kumulatif.
        cumulativeSum += prediction;

        // Buat objek hasil untuk segmen ini.
        final segmentLabel = 'Segment ${i + 1}';
        final result = SegmentResult(
          label: segmentLabel,
          predicted: prediction,
          cumulative: cumulativeSum,
        );

        results.add(result);

        debugPrint('   📈 Prediction: $prediction');
        debugPrint('   ∑ Cumulative: $cumulativeSum');
        debugPrint('');
      }

      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║       ✅ Batch Processing Complete                       ║');
      debugPrint('║   Total Segments: ${rawSegments.length}');
      debugPrint('║   Total Estimated Time: $cumulativeSum');
      debugPrint('╚══════════════════════════════════════════════════════════╝');

      return results;
    } catch (e) {
      debugPrint('❌ Batch processing error: $e');
      rethrow;
    }
  }

  /// Menginisialisasi semua komponen yang diperlukan (scaler dan model).
  /// Harus dipanggil sebelum menggunakan layanan ini.
  Future<void> initialize() async {
    try {
      debugPrint('\n');
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║    Initializing Inference Pipeline Components            ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝\n');

      // Muat parameter scaler dari file.
      await _scalerService.loadScaler();
      debugPrint('');

      // Muat model TFLite dari assets.
      await _tfliteService.loadModel();
      debugPrint('');

      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║    ✅ All Components Initialized Successfully            ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝\n');
    } catch (e) {
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║    ❌ Initialization Failed                              ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('Error: $e');
      rethrow;
    }
  }

  /// Membersihkan sumber daya yang digunakan (menutup model TFLite).
  void dispose() {
    _tfliteService.close();
    debugPrint('🧹 Inference service resources cleaned up');
  }
}
