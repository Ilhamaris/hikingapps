import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/route_point.dart';

// Layanan untuk memuat data rute pendakian dari file JSON.
// Mengubah data JSON menjadi daftar objek RoutePoint yang bisa
// digunakan untuk menampilkan jalur pada peta.
class RouteLoader {
  // Memuat rute dari path file tertentu di assets.
  // Mengembalikan daftar titik rute yang sudah diparsing.
  static Future<List<RoutePoint>> loadRoute(String path) async {
    // Baca isi file sebagai string JSON.
    final raw = await rootBundle.loadString(path);
    // Parse string menjadi daftar objek dinamis.
    final List data = jsonDecode(raw);
    // Ubah setiap objek menjadi RoutePoint.
    return data.map((e) => RoutePoint.fromJson(e)).toList();
  }
}
