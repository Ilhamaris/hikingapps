import 'package:flutter/material.dart';

/// Widget bottom sheet untuk menampilkan estimasi waktu perjalanan ke setiap pos
/// Menunjukkan daftar pos-pos dalam rute dengan estimasi waktu tempuh ke masing-masing pos
class BottomSheetEstimation extends StatelessWidget {
  /// Daftar segmen rute dengan estimasi waktu ke setiap pos
  final List<EstimationSegment> segments;

  /// Konstruktor untuk BottomSheetEstimation
  /// [segments] adalah daftar pos-pos dengan estimasi waktu yang akan ditampilkan
  const BottomSheetEstimation({
    super.key,
    required this.segments,
  });

  /// Membangun UI bottom sheet dengan header dan daftar segmen
  /// Menggunakan Column dengan mainAxisSize.min agar bottom sheet menyesuaikan tinggi konten
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        // Membulatkan bagian atas bottom sheet
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue[500], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Estimasi Waktu ke Pos', // Judul bottom sheet
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // Membangun daftar segmen rute menggunakan List.generate
            child: Column(
              children: List.generate(
                segments.length,
                (index) => _buildSegment(segments[index]),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Membangun widget untuk setiap segmen rute dengan estimasi waktu
  /// Menampilkan ikon lokasi, nama pos, dan estimasi waktu dalam format jam dan menit
  Widget _buildSegment(EstimationSegment segment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Ikon lokasi dengan circle badge berwarna hijau
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Icon(
                Icons.location_on,
                color: Colors.green,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  segment.location, // Nama lokasi/pos
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${segment.hours} jam ${segment.minutes} menit', // Estimasi waktu tempuh
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Model data untuk menyimpan informasi estimasi waktu ke sebuah pos
/// Berisi nama lokasi dan estimasi waktu dalam jam dan menit
class EstimationSegment {
  /// Nama lokasi atau pos tujuan
  final String location;

  /// Estimasi waktu dalam jam
  final int hours;

  /// Estimasi waktu dalam menit
  final int minutes;

  /// Konstruktor untuk EstimationSegment
  /// [location] nama pos, [hours] jam estimasi, [minutes] menit estimasi
  EstimationSegment({
    required this.location,
    required this.hours,
    required this.minutes,
  });
}
