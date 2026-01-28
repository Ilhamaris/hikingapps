import 'package:flutter/material.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import '../services/gpx_service.dart';
import '../services/bounding_box_calculator.dart';
import '../services/tile_download_service.dart';
import '../services/tile_cache_status_service.dart';

// Layar untuk input parameter berat badan dan tas sebelum memulai pendakian
class InputParameterScreen extends StatefulWidget {
  const InputParameterScreen({super.key});

  @override
  State<InputParameterScreen> createState() => _InputParameterScreenState();
}

// Kelas State untuk mengelola input parameter pendakian
class _InputParameterScreenState extends State<InputParameterScreen> {
  // Pengontrol untuk input berat badan pengguna dalam kilogram
  final _bodyWeightController = TextEditingController();
  // Pengontrol untuk input berat tas/perlengkapan dalam kilogram
  final _bagWeightController = TextEditingController();

  // Membersihkan pengontrol saat widget dihapus dari memori
  @override
  void dispose() {
    _bodyWeightController.dispose();
    _bagWeightController.dispose();
    super.dispose();
  }

  // Membangun tampilan form input parameter pendakian
  @override
  Widget build(BuildContext context) {
    // Mengambil argumen gunung dan jalur dari navigasi sebelumnya
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final mountain = args?['mountain'] as Mountain?;
    final route = args?['route'] as HikingRoute?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Input Parameter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jalur yang dipilih:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${route?.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Body Weight Input
              const Text(
                'Jalur yang dipilih:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _bodyWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 70',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.monitor_weight, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Bag Weight Input
              const Text(
                'Berat Tas (kg)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _bagWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 15',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.backpack, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Start Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final bodyWeight = _bodyWeightController.text;
                    final bagWeight = _bagWeightController.text;

                    if (bodyWeight.isEmpty || bagWeight.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan isi semua parameter'),
                        ),
                      );
                      return;
                    }

                    // Tampilkan dialog untuk mengecek dan mengunduh tile jika diperlukan
                    if (context.mounted) {
                      _showTileDownloadDialog(
                        context,
                        route!,
                        mountain!,
                        double.parse(bodyWeight),
                        double.parse(bagWeight),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Mulai Pendakian',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan dialog untuk mengecek dan mengunduh tile jika diperlukan
  /// 
  /// Dialog akan:
  /// 1. Mengecek apakah tile sudah diunduh
  /// 2. Jika belum, tampilkan loading dan unduh tile
  /// 3. Jika sudah, langsung navigasi ke halaman peta
  void _showTileDownloadDialog(
    BuildContext context,
    HikingRoute route,
    Mountain mountain,
    double bodyWeight,
    double bagWeight,
  ) async {
    // Cek apakah tile sudah diunduh sebelumnya
    final isCached = await TileCacheStatusService.isCacheDownloaded(
      route.gpxFileName,
    );

    if (!context.mounted) return;

    if (isCached) {
      // Jika tile sudah ada, langsung navigasi ke peta
      Navigator.pushNamed(
        context,
        '/hiking-map',
        arguments: {
          'mountain': mountain,
          'route': route,
          'bodyWeight': bodyWeight,
          'bagWeight': bagWeight,
        },
      );
    } else {
      // Jika tile belum ada, tampilkan dialog untuk mengunduh
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _TileDownloadDialog(
          route: route,
          mountain: mountain,
          bodyWeight: bodyWeight,
          bagWeight: bagWeight,
        ),
      );
    }
  }
}

/// Widget dialog untuk mengunduh tile peta
class _TileDownloadDialog extends StatefulWidget {
  final HikingRoute route;
  final Mountain mountain;
  final double bodyWeight;
  final double bagWeight;

  const _TileDownloadDialog({
    required this.route,
    required this.mountain,
    required this.bodyWeight,
    required this.bagWeight,
  });

  @override
  State<_TileDownloadDialog> createState() => _TileDownloadDialogState();
}

class _TileDownloadDialogState extends State<_TileDownloadDialog> {
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  /// Memulai proses download tile untuk jalur yang dipilih
  void _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      // Muat track points dari file GPX
      final trackPoints = await GPXService.loadGPXTrack(
        widget.route.gpxFileName,
      );

      if (!mounted) return;

      // Hitung bounding box dari track points
      final boundingBox = BoundingBoxCalculator.calculateBoundingBox(
        trackPoints,
      );

      // Unduh tile untuk area yang sudah dihitung
      await TileDownloadService.downloadTilesForRoute(
        boundingBox,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      // Tandai jalur sebagai sudah diunduh
      await TileCacheStatusService.setCacheDownloaded(
        widget.route.gpxFileName,
      );

      if (!mounted) return;

      // Tutup dialog dan navigasi ke halaman peta
      Navigator.pop(context);
      Navigator.pushNamed(
        context,
        '/hiking-map',
        arguments: {
          'mountain': widget.mountain,
          'route': widget.route,
          'bodyWeight': widget.bodyWeight,
          'bagWeight': widget.bagWeight,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Gagal mengunduh tile: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mengunduh Peta Offline'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
            ),
            const SizedBox(height: 16),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mengunduh tile peta untuk area offline...',
              textAlign: TextAlign.center,
            ),
          ] else if (_errorMessage != null) ...[
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
          ],
        ],
      ),
      actions: [
        if (_errorMessage != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
      ],
    );
  }
}