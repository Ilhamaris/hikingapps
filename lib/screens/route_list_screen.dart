import 'package:flutter/material.dart';
import '../models/mountain.dart';
import '../models/hiking_route.dart';
import '../widgets/route_card.dart';

class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil data gunung yang dipilih dari argumen navigasi sebelumnya
    final mountain = ModalRoute.of(context)?.settings.arguments as Mountain?;

    // Data dummy
    final routes = [
      HikingRoute(
        id: '1',
        name: 'Jalur Selo',
        distance: 6.5,
        gpxFileName: 'jalur_selo.gpx',
        waypoints: ['Pos 1 Selo', 'Pos 2 Selo', 'Puncak'],
      ),
      HikingRoute(
        id: '2',
        name: 'Jalur Wekas',
        distance: 8.2,
        gpxFileName: 'jalur_wekas.gpx',
        waypoints: ['Pos 1', 'Pos 2', 'Pos 3', 'Puncak'],
      ),
    ];

    // header
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
            // Daftar jalur pendakian
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
