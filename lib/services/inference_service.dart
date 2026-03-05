import 'package:flutter/foundation.dart';
import '../models/segment_result.dart';
import 'scaler_service.dart';
import 'tflite_service.dart';

/// Service for preprocessing segment data and running batch inference
class InferenceService {
  static final InferenceService _instance = InferenceService._internal();

  InferenceService._internal();

  factory InferenceService() {
    return _instance;
  }

  final ScalerService _scalerService = ScalerService();
  final TFLiteService _tfliteService = TFLiteService();

  /// Preprocess a single segment data
  /// Extracts and scales the 5 required features in order:
  /// 1. body_weight
  /// 2. load_weight
  /// 3. delta_dist_m
  /// 4. delta_elev_m
  /// 5. slope_deg
  List<double> preprocessSegment(
    Map<String, dynamic> segmentData,
    double bodyWeight,
    double loadWeight,
  ) {
    try {
      // Extract the 5 features in the mandatory order
      final deltaDistM = (segmentData['delta_dist_m'] as num).toDouble();
      final deltaElevM = (segmentData['delta_elev_m'] as num).toDouble();
      final slopeDeg = (segmentData['slope_deg'] as num).toDouble();

      final rawFeatures = [bodyWeight, loadWeight, deltaDistM, deltaElevM, slopeDeg];

      // Scale the features
      final scaledFeatures = _scalerService.scaleFeatures(rawFeatures);

      debugPrint('📐 Preprocessed Segment:');
      debugPrint('   - Raw features: $rawFeatures');
      debugPrint('   - Scaled features: $scaledFeatures');

      return scaledFeatures;
    } catch (e) {
      debugPrint('❌ Preprocessing error: $e');
      rethrow;
    }
  }

  /// Process multiple segments with cumulative calculation
  /// Requires: bodyWeight and loadWeight from user input
  /// Returns list of SegmentResult with predictions and cumulative sum
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
      double cumulativeSum = 0.0;

      for (int i = 0; i < rawSegments.length; i++) {
        final segment = rawSegments[i];

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🔄 Processing Segment ${i + 1}/${rawSegments.length}');

        // Preprocess the segment
        final scaledFeatures = preprocessSegment(segment, bodyWeight, loadWeight);

        // Run inference
        final prediction = _tfliteService.runInference(scaledFeatures);

        // Accumulate
        cumulativeSum += prediction;

        // Create result
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

  /// Initialize all required services
  Future<void> initialize() async {
    try {
      debugPrint('\n');
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║    Initializing Inference Pipeline Components            ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝\n');

      // Load scaler
      await _scalerService.loadScaler();
      debugPrint('');

      // Load model
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

  /// Clean up resources
  void dispose() {
    _tfliteService.close();
    debugPrint('🧹 Inference service resources cleaned up');
  }
}
