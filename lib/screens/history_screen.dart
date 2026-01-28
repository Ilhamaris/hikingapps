import 'package:flutter/material.dart';
import '../models/hiking_history.dart';

// Layar untuk menampilkan daftar riwayat pendakian yang pernah dilakukan
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Membangun tampilan daftar riwayat pendakian
  @override
  Widget build(BuildContext context) {
    // Data dummy untuk demonstrasi riwayat pendakian
    final histories = [
      HikingHistory(
        id: 1,
        mountainName: 'Gunung Gede',
        routeName: 'Jalur Cibodas',
        date: DateTime(2025, 12, 15),
        estimatedTime: const Duration(hours: 4, minutes: 30),
        bodyWeight: 70,
        bagWeight: 12,
        segments: [
          RouteSegment(
            from: 'Pos 1 Cibodas',
            to: 'Pos 2 Cibodas',
            estimatedTime: const Duration(minutes: 45),
          ),
          RouteSegment(
            from: 'Pos 2 Cibodas',
            to: 'Pos 3 Kandang Batu',
            estimatedTime: const Duration(minutes: 60),
          ),
          RouteSegment(
            from: 'Pos 3 Kandang Batu',
            to: 'Puncak Gunung',
            estimatedTime: const Duration(minutes: 45),
          ),
        ],
      ),
      HikingHistory(
        id: 2,
        mountainName: 'Gunung Merbabu',
        routeName: 'Jalur Selo',
        date: DateTime(2025, 12, 8),
        estimatedTime: const Duration(hours: 5, minutes: 20),
        bodyWeight: 70,
        bagWeight: 15,
        segments: [
          RouteSegment(
            from: 'Pos 1 Selo',
            to: 'Pos 2 Selo',
            estimatedTime: const Duration(minutes: 30),
          ),
        ],
      ),
    ];

    // header
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Riwayat Pendakian',
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
        child: Column(
          children: [
            ...histories.map((history) {
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/history-detail',
                    arguments: history,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  history.mountainName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  history.routeName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${history.date.day} ${_getMonthName(history.date.month)} ${history.date.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total Naik: ${history.estimatedTime.inHours}j ${history.estimatedTime.inMinutes % 60}m',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.show_chart,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total Turun: 3j 15m',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }
}
