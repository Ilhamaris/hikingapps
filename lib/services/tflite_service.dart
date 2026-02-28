import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

/// Service for loading and managing TFLite model operations
class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();

  TFLiteService._internal();

  factory TFLiteService() {
    return _instance;
  }

  tflite.Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Load TFLite model from assets
  /// Initializes the interpreter and sets up threads
  Future<void> loadModel() async {
    try {
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║       Starting TFLite Model Loading Process              ║');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('📍 Attempting to load: assets/models/linear_regression.tflite');

      _interpreter = await tflite.Interpreter.fromAsset(
        'assets/models/linear_regression.tflite',
      );

      if (_interpreter != null) {
        // Configure threads for better performance
        _interpreter!.allocateTensors();

        debugPrint('✅ Model loaded successfully!');
        debugPrint('📊 Model Details:');
        debugPrint('   - Input tensors: ${_interpreter!.getInputTensors().length}');
        debugPrint('   - Output tensors: ${_interpreter!.getOutputTensors().length}');

        for (int i = 0; i < _interpreter!.getInputTensors().length; i++) {
          final tensor = _interpreter!.getInputTensors()[i];
          debugPrint('   - Input $i: shape=${tensor.shape}, dtype=${tensor.type}');
        }

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

  /// Check if model is initialized
  bool isInitialized() => _isInitialized;

  /// Run inference on input data
  /// Input: List of 3 scaled features [delta_dist_m, delta_elev_m, slope_deg]
  /// Returns: Predicted value as double
  double runInference(List<double> input) {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Model not initialized. Call loadModel() first.');
    }

    if (input.length != 3) {
      throw Exception('Input must contain exactly 3 features, got ${input.length}');
    }

    try {
      // Prepare input in the correct shape [1, 3]
      final inputData = [input];

      // Determine output shape dynamically and allocate a buffer.
      // Many simple regression models produce a tensor shape [1, 1],
      // so we make a 2D list and then read the single value.
      final outTensor = _interpreter!.getOutputTensors().first;
      final shape = outTensor.shape;

      late dynamic outputBuffer;
      if (shape.length == 2) {
        // e.g. [1,1] -> [[0.0]]
        outputBuffer = List.generate(
          shape[0],
          (_) => List<double>.filled(shape[1], 0.0),
        );
      } else if (shape.length == 1) {
        outputBuffer = List<double>.filled(shape[0], 0.0);
      } else {
        // fallback to a flat buffer
        outputBuffer = List<double>.filled(shape.reduce((a, b) => a * b), 0.0);
      }

      // Run inference; using run() handles both single and multiple input cases
      _interpreter!.run(inputData, outputBuffer);

      // Extract prediction from buffer in a generic way
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

  /// Close the interpreter and release resources
  void close() {
    if (_interpreter != null) {
      _interpreter!.close();
      _isInitialized = false;
      debugPrint('🔌 TFLite interpreter closed and resources released');
    }
  }
}
