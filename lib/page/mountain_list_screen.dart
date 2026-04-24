import 'package:flutter/material.dart';
import '../models/mountain.dart';
import '../services/mountain_loader.dart';
import '../widgets/mountain_card.dart';

// Layar untuk menampilkan daftar gunung yang tersedia untuk pendakian
class MountainListScreen extends StatefulWidget {
  const MountainListScreen({super.key});

  @override
  State<MountainListScreen> createState() => _MountainListScreenState();
}

class _MountainListScreenState extends State<MountainListScreen> {
  late Future<List<Mountain>> _mountainsFuture;

  @override
  void initState() {
    super.initState();
    _mountainsFuture = MountainLoader.loadAllMountains();
  }

  // Membangun tampilan daftar gunung
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // AppBar (header) dengan judul dan tombol kembali
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
      // Body utama yang menampilkan daftar gunung dengan FutureBuilder untuk menangani data asinkron
      body: FutureBuilder<List<Mountain>>(
        future: _mountainsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading mountains: ${snapshot.error}'),
            );
          }

          final mountains = snapshot.data ?? [];

          if (mountains.isEmpty) {
            return const Center(
              child: Text('No mountains found'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Field pencarian untuk mencari gunung berdasarkan nama
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
          );
        },
      ),
    );
  }
}
