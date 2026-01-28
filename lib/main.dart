import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/mountain_list_screen.dart';
import 'screens/route_list_screen.dart';
import 'screens/input_parameter_screen.dart';
import 'screens/history_screen.dart';
import 'screens/history_detail_screen.dart';

// Fungsi menjalankan aplikasi
void main() {
  runApp(const MyApp());
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prediksi Waktu Pendakian',
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
      routes: {
        '/home': (context) => const HomeScreen(), // Layar beranda
        '/mountain-list': (context) => const MountainListScreen(),
        '/route-list': (context) => const RouteListScreen(),
        '/input-parameter': (context) => const InputParameterScreen(),
        '/history': (context) => const HistoryScreen(),
        '/history-detail': (context) => const HistoryDetailScreen(),
      },
    );
  }
}
