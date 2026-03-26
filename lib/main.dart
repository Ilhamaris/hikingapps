import 'package:flutter/material.dart';
import 'page/home_screen.dart';
import 'page/mountain_list_screen.dart';
import 'page/route_list_screen.dart';
import 'page/input_parameter_screen.dart';
import 'page/history_screen.dart';
import 'page/history_detail_screen.dart';
import 'page/hiking_map_screen.dart';
import 'page/estimation_screen.dart';
import 'models/mountain.dart';
import 'models/hiking_route.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Fungsi utama aplikasi. Dipanggil pertama kali saat aplikasi berjalan.
// Melakukan inisialisasi widget binding dan menampilkan splash screen native
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Menjaga splash screen hingga runApp dieksekusi
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );
  runApp(const MyApp()); // Menjalankan widget root
  FlutterNativeSplash.remove(); // Menghapus splash screen setelah aplikasi siap
}

/// Widget utama aplikasi
/// Mengatur tema umum, jalur navigasi, serta layar awal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Judul yang muncul di sistem operasi (misal recent apps)
      title: 'Prediksi Waktu Pendakian',
      theme: ThemeData(
        primaryColor: Colors.green, // Warna dasar aplikasi
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
        // Tema khusus untuk tombol FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
        ),
        // Tema untuk tombol terangkat (ElevatedButton)
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
      home: const HomeScreen(), // Layar awal saat aplikasi dibuka
      // Definisi daftar rute navigasi dinamika
      routes: {
        '/home': (context) => const HomeScreen(), // Halaman beranda
        '/mountain-list': (context) => const MountainListScreen(),
        '/route-list': (context) => const RouteListScreen(),
        '/input-parameter': (context) => const InputParameterScreen(),
        '/history': (context) => const HistoryScreen(),
        '/history-detail': (context) => const HistoryDetailScreen(),
        '/estimation': (context) => const EstimationScreen(),
        // Rute khusus yang memerlukan argumen kompleks
        '/hiking-map': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final mountain = args?['mountain'] as Mountain?;
          final route = args?['route'] as HikingRoute?;
          final bodyWeight = args?['bodyWeight'] as double? ?? 0.0;
          final bagWeight = args?['bagWeight'] as double? ?? 0.0;

          // Validasi argumen, tampilkan error jika data hilang
          if (mountain == null || route == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Mountain or Route data is missing'),
              ),
            );
          }

          // Jika argumen valid, tampilkan halaman peta hiking
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
