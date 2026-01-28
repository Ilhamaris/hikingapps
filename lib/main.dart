import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/mountain_list_screen.dart';
import 'screens/route_list_screen.dart';
import 'screens/input_parameter_screen.dart';
import 'screens/hiking_map_screen.dart';
import 'screens/history_screen.dart';
import 'screens/history_detail_screen.dart';

// Fungsi utama yang menjalankan aplikasi Flutter
void main() async {
  // Inisialisasi flutter_map_tile_caching sebelum menjalankan aplikasi
  // Tile caching akan diinisialisasi secara otomatis saat pertama kali digunakan
  runApp(const MyApp());
}

/// Widget utama aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prediksi Waktu Pendakian', // Judul aplikasi
      theme: ThemeData(
        primaryColor: Colors.green, // Warna utama aplikasi
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Tema untuk Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
        ),
        // Tema untuk Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomeScreen(), // Layar pertama yang ditampilkan
      // rute navigasi aplikasi
      routes: {
        '/home': (context) => const HomeScreen(), // Layar beranda
        '/mountain-list': (context) => const MountainListScreen(),
        '/route-list': (context) => const RouteListScreen(),
        '/input-parameter': (context) => const InputParameterScreen(),
        '/hiking-map': (context) => const HikingMapScreen(),
        '/history': (context) => const HistoryScreen(),
        '/history-detail': (context) => const HistoryDetailScreen(),
      },
    );
  }
}
