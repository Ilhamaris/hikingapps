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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _mountainsFuture = MountainLoader.loadAllMountains();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          final filteredMountains = mountains.where((mountain) {
            final query = _searchQuery.toLowerCase();
            return mountain.name.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
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
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: mountains.isEmpty
                    ? const Center(
                        child: Text('No mountains found'),
                      )
                    : filteredMountains.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 96,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Maaf, Gunung Belum Ditambahkan!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredMountains.length,
                            itemBuilder: (context, index) {
                              final mountain = filteredMountains[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: MountainCard(
                                  mountain: mountain,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/route-list',
                                      arguments: mountain,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
