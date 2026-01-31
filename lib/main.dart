import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/mountain_list_screen.dart';
import 'screens/route_list_screen.dart';
import 'screens/input_parameter_screen.dart';
import 'screens/history_screen.dart';
import 'screens/history_detail_screen.dart';
import 'screens/hiking_map_screen.dart';
import 'models/mountain.dart';
import 'models/hiking_route.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Fungsi utama yang menjalankan aplikasi Flutter
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );
  runApp(const MyApp());
  FlutterNativeSplash.remove();
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
        '/history': (context) => const HistoryScreen(),
        '/history-detail': (context) => const HistoryDetailScreen(),
        '/hiking-map': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final mountain = args?['mountain'] as Mountain?;
          final route = args?['route'] as HikingRoute?;
          final bodyWeight = args?['bodyWeight'] as double? ?? 0.0;
          final bagWeight = args?['bagWeight'] as double? ?? 0.0;

          if (mountain == null || route == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Mountain or Route data is missing'),
              ),
            );
          }

          return HikingMapScreen(
            mountain: mountain,
            route: route,
            bodyWeight: bodyWeight,
            bagWeight: bagWeight,
          );
        },
      },
    );
  }
}
