import 'package:flutter/material.dart';
import '../models/mountain.dart';

// Widget kartu yang menampilkan informasi dasar gunung, termasuk nama,
// ketinggian, lokasi, dan deskripsi singkat. Kartu ini bisa diklik
// untuk memilih gunung dan melihat rute-rutenya.
class MountainCard extends StatelessWidget {
  // Data gunung yang akan ditampilkan pada kartu.
  final Mountain mountain;
  // Fungsi yang dipanggil saat kartu diklik (biasanya navigasi ke daftar rute).
  final VoidCallback onTap;

  const MountainCard({
    super.key,
    required this.mountain,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Mengaktifkan callback saat diklik.
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Bayangan untuk efek visual yang menarik.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ikon gunung dengan background hijau muda.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.terrain,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mountain.name, // Nama gunung dari data.
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mountain.elevation.toStringAsFixed(0)} mdpl • ${mountain.location}', // Ketinggian (meter di atas permukaan laut) dan lokasi.
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
              const SizedBox(height: 12),
              // Deskripsi gunung, dibatasi maksimal 3 baris dengan ellipsis jika terlalu panjang.
              Text(
                mountain.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                // Tombol hijau untuk memilih gunung ini dan melihat jalur.
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Pilih Jalur',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
}
