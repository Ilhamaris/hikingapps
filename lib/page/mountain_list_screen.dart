import 'package:flutter/material.dart';
import '../models/mountain.dart';
import '../widgets/mountain_card.dart';

// Layar untuk menampilkan daftar gunung yang tersedia untuk pendakian
class MountainListScreen extends StatelessWidget {
  const MountainListScreen({super.key});

  // Membangun tampilan daftar gunung
  @override
  Widget build(BuildContext context) {
    // Data dummy untuk daftar gunung (data simulasi)
    final mountains = [
      Mountain(
        id: '1',
        name: 'Gunung Gede',
        location: 'Jawa Barat',
        elevation: 2958,
        description:
            'Gunung berapi yang terletak di Taman Nasional Gunung Gede Pangrango. Menawarkan pemandangan alam yang indah dengan beragam jalur pendakian.',
        imagePath: 'assets/images/gede.jpg',
      ),
      Mountain(
        id: '2',
        name: 'Gunung Semeru',
        location: 'Jawa Timur',
        elevation: 3676,
        description:
            'Gunung tertinggi di Pulau Jawa dengan puncak Mahameru yang menantang. Jalur pendakian berpengalaman.',
        imagePath: 'assets/images/semeru.jpg',
      ),
      Mountain(
        id: '3',
        name: 'Gunung Merbabu',
        location: 'Jawa Tengah',
        elevation: 3145,
        description:
            'Gunung dengan pemandangan savana luas dan jalur pendakian yang beragam. Cocok untuk berbagai tingkat pendaki.',
        imagePath: 'assets/images/merbabu.jpg',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Informasi Gunung',
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama gunung...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            ...mountains.map((mountain) {
              return MountainCard(
                mountain: mountain,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/route-list',
                    arguments: mountain,
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
