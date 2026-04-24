import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/segment_result.dart';
import '../services/inference_service.dart';
import '../widgets/estimation_bottom_sheet.dart';

/// Screen for testing the complete inference pipeline using
/// route segments from assets folder
class EstimationScreen extends StatefulWidget {
  const EstimationScreen({super.key});

  @override
  State<EstimationScreen> createState() => _EstimationScreenState();
}

class _EstimationScreenState extends State<EstimationScreen> {
  late InferenceService _inferenceService;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing...';
  List<SegmentResult> _results = [];
  bool _showBottomSheet = false;

  @override
  void initState() {
    super.initState();
    _inferenceService = InferenceService();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _inferenceService.initialize();
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready to process segments';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Fungsi ini memicu pemrosesan segmen dari file JSON di assets
  // layanan inference. Digunakan untuk menguji pipeline tanpa
  // menavigasi melalui peta.
  Future<void> _processTestSegments() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Services not initialized')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Loading segments from assets...';
    });

    try {
      // Load segments from assets
      final segments = await _loadSegmentsFromAssets();

      if (segments.isEmpty) {
        throw Exception('No segments found in assets');
      }

      // Test values for body weight and load weight
      const double bodyWeight = 70.0; // kg
      const double loadWeight = 15.0; // kg

      // Process segments
      final results = _inferenceService.processSegments(
        segments,
        bodyWeight,
        loadWeight,
      );

      setState(() {
        _results = results;
        _isProcessing = false;
        _statusMessage =
            'Processed ${results.length} segments successfully!';
        _showBottomSheet = true;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Processing failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Load trail segments from assets folder
  Future<List<Map<String, dynamic>>> _loadSegmentsFromAssets() async {
    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('routes/glonggong/mongkrang/route_segments.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load segments: $e');
    }
  }

  @override
  void dispose() {
    _inferenceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiking Time Estimation'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Status card
              Container(
                color: Colors.grey.shade50,
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isInitialized
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Info section
              if (_isInitialized)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pipeline Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                _buildStatusItem(
                                  icon: Icons.check_circle,
                                  label: 'Scaler Model',
                                  status: 'Loaded',
                                  isSuccess: true,
                                ),
                                const Divider(),
                                _buildStatusItem(
                                  icon: Icons.check_circle,
                                  label: 'TFLite Model',
                                  status: 'Loaded',
                                  isSuccess: true,
                                ),
                                const Divider(),
                                _buildStatusItem(
                                  icon: Icons.settings,
                                  label: 'Inference Service',
                                  status: 'Ready',
                                  isSuccess: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Route Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Segments will be loaded from assets/routes/glonggong/mongkrang/route_segments.json',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!_isInitialized)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.green.shade400,
                    ),
                  ),
                ),
            ],
          ),

          // Bottom sheet overlay
          if (_showBottomSheet)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: EstimationBottomSheet(
                results: _results,
                onClose: () {
                  setState(() {
                    _showBottomSheet = false;
                  });
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _isInitialized && !_isProcessing
          ? FloatingActionButton.extended(
              onPressed: _processTestSegments,
              label: const Text('Process Segments'),
              icon: const Icon(Icons.play_arrow),
              backgroundColor: Colors.green,
            )
          : _isProcessing
              ? FloatingActionButton(
                  onPressed: null,
                  backgroundColor: Colors.green.shade300,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : null,
    );
  }

  // Widget helper yang membuat baris status dengan ikon dan label
  // digunakan di layar untuk menampilkan status tiap langkah pemrosesan
  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String status,
    required bool isSuccess,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: isSuccess ? Colors.green : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
}
