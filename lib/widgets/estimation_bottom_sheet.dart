import 'package:flutter/material.dart';
import '../models/segment_result.dart';

/// Widget untuk menampilkan card hasil estimasi segmen tunggal
/// Menunjukkan informasi segmen seperti waktu estimasi dan jarak
class SegmentResultCard extends StatelessWidget {
  /// Hasil estimasi segmen yang akan ditampilkan
  final SegmentResult result;

  /// Indeks segmen dalam daftar (dimulai dari 0)
  final int index;

  /// Konstruktor untuk SegmentResultCard
  const SegmentResultCard({
    super.key,
    required this.result,
    required this.index,
  });

  /// Membangun UI card untuk menampilkan hasil estimasi segmen
  /// Menggunakan gradient background dan menampilkan nomor segmen, label, dan waktu estimasi
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segment label and index - nomor dan nama segmen
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Divider - garis pemisah
              Divider(
                color: Colors.green.shade300,
                thickness: 1,
              ),
              const SizedBox(height: 12),

              // Prediction value - nilai prediksi waktu segmen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Segment Prediction:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${result.predicted.toStringAsFixed(2)} min',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cumulative value - waktu kumulatif dari awal perjalanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cumulative Time:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${result.cumulative.toStringAsFixed(2)} min',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for displaying estimation results
/// Widget EstimationBottomSheet adalah widget stateful yang menampilkan hasil estimasi waktu hiking
/// dalam bentuk bottom sheet yang dapat di-drag. Widget ini menunjukkan daftar segmen perjalanan
/// dengan waktu estimasi kumulatif dan memungkinkan pengguna menarik untuk memperbesar atau memperkecil tampilan.
class EstimationBottomSheet extends StatefulWidget {
  /// Daftar hasil estimasi segmen yang akan ditampilkan dalam bottom sheet
  final List<SegmentResult> results;

  /// Callback yang dipanggil ketika bottom sheet ditutup
  final VoidCallback onClose;

  /// Konstruktor untuk EstimationBottomSheet
  /// [results] adalah daftar hasil estimasi segmen yang akan ditampilkan
  /// [onClose] adalah callback yang dipanggil ketika pengguna menekan tombol tutup
  const EstimationBottomSheet({
    super.key,
    required this.results,
    required this.onClose,
  });

  @override
  State<EstimationBottomSheet> createState() => _EstimationBottomSheetState();
}

class _EstimationBottomSheetState extends State<EstimationBottomSheet>
    with SingleTickerProviderStateMixin {
  /// Controller untuk mengatur animasi drag bottom sheet
  late AnimationController _animationController;

  /// Animasi untuk transisi tinggi bottom sheet
  late Animation<double> _animation;

  /// Posisi drag saat ini untuk menghitung perubahan tinggi
  double _dragPosition = 0;

  /// Tinggi minimum bottom sheet (25% dari layar)
  final double _minHeight = 0.25;

  /// Tinggi maksimum bottom sheet (100% dari layar)
  final double _maxHeight = 1.0;

  /// Tinggi saat ini dari bottom sheet
  late double _currentHeight;

  /// Inisialisasi state ketika widget pertama kali dibuat
  /// Mengatur tinggi awal ke minimum dan membuat animation controller
  @override
  void initState() {
    super.initState();
    _currentHeight = _minHeight;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: _minHeight, end: _minHeight).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addListener(() {
      setState(() {
        _currentHeight = _animation.value;
      });
    });
  }

  /// Membersihkan resource ketika widget dihapus
  /// Dispose animation controller untuk mencegah memory leak
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Menangani awal drag gesture
  /// Menyimpan posisi awal drag untuk menghitung perubahan
  void _handleDragStart(double position) {
    _dragPosition = position;
  }

  /// Menangani update selama drag gesture
  /// Menghitung tinggi baru berdasarkan pergerakan jari dan membatasi dalam rentang minimum-maksimum
  void _handleDragUpdate(double position) {
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = _dragPosition - position;
    final newHeight = (_currentHeight * screenHeight + delta) / screenHeight;

    setState(() {
      _currentHeight = newHeight.clamp(_minHeight, _maxHeight);
    });

    _dragPosition = position;
  }

  /// Menangani akhir drag gesture
  /// Menganimasikan bottom sheet ke posisi terdekat (minimum atau maksimum)
  void _handleDragEnd() {
    // Snap to nearest position
    final snapThreshold = 0.5;
    final targetHeight =
        _currentHeight < snapThreshold ? _minHeight : _maxHeight;

    _animation = Tween<double>(begin: _currentHeight, end: targetHeight).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _currentHeight = targetHeight;
      });
    });
  }

  /// Membangun UI bottom sheet dengan gesture detector untuk drag
  /// Menghitung tinggi berdasarkan state saat ini dan membuat container dengan rounded corner
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = _currentHeight * screenHeight;

    return GestureDetector(
      onVerticalDragStart: (details) => _handleDragStart(details.globalPosition.dy),
      onVerticalDragUpdate: (details) => _handleDragUpdate(details.globalPosition.dy),
      onVerticalDragEnd: (_) => _handleDragEnd(),
      child: Container(
        height: bottomSheetHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar - bilah untuk menarik bottom sheet
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header - bagian atas dengan judul dan tombol tutup
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimation Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.grey,
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  // Menampilkan total waktu estimasi jika ada hasil
                  if (widget.results.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Total Estimated Time: ${widget.results.last.cumulative.toStringAsFixed(2)} minutes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Divider - garis pemisah antara header dan daftar
            Divider(
              color: Colors.grey.shade200,
              height: 1,
              thickness: 1,
            ),

            // Segments list - daftar segmen hasil estimasi
            Expanded(
              child: widget.results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade400,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results available',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: widget.results.length,
                      itemBuilder: (context, index) {
                        // Membuat card untuk setiap segmen hasil estimasi
                        return SegmentResultCard(
                          result: widget.results[index],
                          index: index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
