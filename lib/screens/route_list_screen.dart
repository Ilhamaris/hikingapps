import 'package:flutter/material.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import '../widgets/route_card.dart';

// Layar untuk menampilkan daftar jalur pendakian untuk gunung yang dipilih
class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key});

  // Membangun tampilan daftar jalur pendakian
  @override
  Widget build(BuildContext context) {
    // Mengambil data gunung yang dipilih dari argumen navigasi sebelumnya
    final mountain = ModalRoute.of(context)?.settings.arguments as Mountain?;

    // Data dummy untuk daftar jalur pendakian (data simulasi)
    final routes = [
      HikingRoute(
        id: '1',
        name: 'Jalur Suwanting',
        distance: 6.5,
        gpxFileName: 'Mount_Merbabu_via_Suwanting.gpx',
        waypoints: ['Pos 1 Suwanting', 'Pos 2 Suwanting', 'Puncak'],
      ),
      HikingRoute(
        id: '2',
        name: 'Jalur Wekas',
        distance: 8.2,
        gpxFileName: 'Mount_Merbabu_via_Suwanting.gpx',
        waypoints: ['Pos 1', 'Pos 2', 'Pos 3', 'Puncak'],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Pilih Jalur Pendakian',
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
              child: Container(
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
                      mountain?.name ?? 'Mountain',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih jalur pendakian yang ingin Anda naiki:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...routes.map((route) {
              return RouteCard(
                route: route,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/input-parameter',
                    arguments: {
                      'mountain': mountain,
                      'route': route,
                    },
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
