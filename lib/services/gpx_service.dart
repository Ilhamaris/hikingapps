import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

class GPXService {
  /// Mengurai file GPX dari assets dan mengembalikan titik lintasan sebagai daftar LatLng
  /// Fungsi inti untuk memuat jalur pendakian dari file GPX
  static Future<List<LatLng>> loadGPXTrack(String gpxFileName) async {
    try {
      // Memuat file GPX dari folder assets
      final gpxString = await rootBundle.loadString('assets/gpx/$gpxFileName');
      
      // Mengurai file XML GPX
      final document = XmlDocument.parse(gpxString);
      final trackPoints = <LatLng>[];
      
      // Mengambil semua titik lintasan (trkpt) dari file GPX
      final trkpts = document.findAllElements('trkpt');
      for (var trkpt in trkpts) {
        final lat = double.tryParse(trkpt.getAttribute('lat') ?? '');
        final lon = double.tryParse(trkpt.getAttribute('lon') ?? '');
        if (lat != null && lon != null) {
          trackPoints.add(LatLng(lat, lon));
        }
      }
      
      return trackPoints;
    } catch (e) {
      // Penanganan error jika parsing GPX gagal
      return [];
    }
  }

  /// Mengambil waypoint dari file GPX dan mengembalikannya sebagai marker
  /// Waypoint dapat berupa pos pendakian (Pos) atau puncak (Puncak)
  static Future<Map<String, LatLng>> loadGPXWaypoints(String gpxFileName) async {
    try {
      final gpxString = await rootBundle.loadString('assets/gpx/$gpxFileName');
      final document = XmlDocument.parse(gpxString);
      
      final waypoints = <String, LatLng>{};
      
      // Mengambil waypoint dari elemen wpt pada file GPX
      final wpts = document.findAllElements('wpt');
      for (var wpt in wpts) {
        final lat = double.tryParse(wpt.getAttribute('lat') ?? '');
        final lon = double.tryParse(wpt.getAttribute('lon') ?? '');
        final nameElement = wpt.findElements('name').firstOrNull;
        final name = nameElement?.innerText ?? 'Waypoint';
        
        if (lat != null && lon != null) {
          waypoints[name] = LatLng(lat, lon);
        }
      }
      
      return waypoints;
    } catch (e) {
      // Penanganan error jika parsing waypoint gagal
      return {};
    }
  }
}
