import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/mountain.dart';
import '../models/mountain_metadata.dart';
import '../models/mountain_route.dart';

// Layanan untuk memuat data gunung, metadata, dan rute dari folder assets.
// Menggunakan rootBundle untuk mengakses file JSON yang disimpan di aplikasi.
class MountainLoader {
  // Path dasar untuk folder rute di assets.
  static const String _routesBasePath = 'assets/routes';

  /// Memuat semua gunung yang tersedia dari folder assets/routes.
  /// Mengembalikan daftar objek Mountain yang berhasil dimuat.
  static Future<List<Mountain>> loadAllMountains() async {
    final mountains = <Mountain>[];

    // Daftar folder gunung yang tersedia (misal glonggong, mongkrang).
    final mountainFolders = ['glonggong', 'mongkrang', 'lawu', 'arjuno']; // Tambahkan nama folder gunung lainnya di sini.

    for (final folder in mountainFolders) {
      try {
        // Muat data gunung dari folder tersebut.
        final mountain = await _loadMountain(folder);
        if (mountain != null) {
          mountains.add(mountain);
        }
      } catch (e) {
        // Lewati gunung yang gagal dimuat, tapi catat error.
        debugPrint('Error loading mountain $folder: $e');
      }
    }

    return mountains;
  }

  /// Memuat data gunung tertentu berdasarkan nama folder.
  /// Membaca file metadata.json untuk mendapatkan detail gunung.
  static Future<Mountain?> _loadMountain(String mountainFolder) async {
    try {
      // Path ke file metadata gunung.
      final metadataPath = '$_routesBasePath/$mountainFolder/metadata.json';
      // Baca isi file sebagai string JSON.
      final metadataJson = await rootBundle.loadString(metadataPath);
      // Parse JSON menjadi objek MountainMetadata.
      final metadata = MountainMetadata.fromJson(jsonDecode(metadataJson));

      // Buat objek Mountain dari data metadata.
      return Mountain(
        id: mountainFolder,
        name: metadata.mountainName,
        location: metadata.province,
        elevation: metadata.elevation.toDouble(),
        description: metadata.description,
        // imagePath: 'assets/images/icon.png', // Path gambar default.
      );
    } catch (e) {
      debugPrint('Failed to load mountain $mountainFolder: $e');
      return null;
    }
  }

  /// Memuat metadata untuk gunung tertentu berdasarkan ID.
  /// Metadata berisi nama gunung, elevasi, provinsi, deskripsi, dan daftar rute.
  static Future<MountainMetadata?> loadMountainMetadata(String mountainId) async {
    try {
      // Path ke file metadata.
      final path = '$_routesBasePath/$mountainId/metadata.json';
      // Baca dan parse JSON.
      final json = await rootBundle.loadString(path);
      return MountainMetadata.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('Failed to load metadata for mountain $mountainId: $e');
      return null;
    }
  }

  /// Memuat rute tertentu dari gunung tertentu.
  /// Rute berisi daftar titik (RoutePoint) yang membentuk jalur pendakian.
  static Future<MountainRoute?> loadRoute(
    String mountainId,
    String routeFile,
  ) async {
    try {
      // Path ke file rute (misal assets/routes/glonggong/rute/route.json).
      final path = '$_routesBasePath/$mountainId/rute/$routeFile';
      // Baca dan parse JSON menjadi MountainRoute.
      final json = await rootBundle.loadString(path);
      return MountainRoute.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('Failed to load route $routeFile for mountain $mountainId: $e');
      return null;
    }
  }
}
