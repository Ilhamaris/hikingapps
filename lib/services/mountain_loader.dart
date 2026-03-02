import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/mountain.dart';
import '../models/mountain_metadata.dart';
import '../models/mountain_route.dart';

class MountainLoader {
  static const String _routesBasePath = 'assets/routes';

  /// Load all available mountains from assets/routes folders
  static Future<List<Mountain>> loadAllMountains() async {
    final mountains = <Mountain>[];

    // Get list of mountain folders - glonggong and mongkrang
    final mountainFolders = ['glonggong', 'mongkrang'];

    for (final folder in mountainFolders) {
      try {
        final mountain = await _loadMountain(folder);
        if (mountain != null) {
          mountains.add(mountain);
        }
      } catch (e) {
        // Skip mountains that fail to load
        debugPrint('Error loading mountain $folder: $e');
      }
    }

    return mountains;
  }

  /// Load a specific mountain by folder name
  static Future<Mountain?> _loadMountain(String mountainFolder) async {
    try {
      final metadataPath = '$_routesBasePath/$mountainFolder/metadata.json';
      final metadataJson = await rootBundle.loadString(metadataPath);
      final metadata = MountainMetadata.fromJson(jsonDecode(metadataJson));

      return Mountain(
        id: mountainFolder,
        name: metadata.mountainName,
        location: metadata.province,
        elevation: metadata.elevation.toDouble(),
        description: metadata.description,
        imagePath: 'assets/images/icon.png', // Default image path
      );
    } catch (e) {
      debugPrint('Failed to load mountain $mountainFolder: $e');
      return null;
    }
  }

  /// Load metadata for a specific mountain
  static Future<MountainMetadata?> loadMountainMetadata(String mountainId) async {
    try {
      final path = '$_routesBasePath/$mountainId/metadata.json';
      final json = await rootBundle.loadString(path);
      return MountainMetadata.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('Failed to load metadata for mountain $mountainId: $e');
      return null;
    }
  }

  /// Load a specific route from a mountain
  static Future<MountainRoute?> loadRoute(
    String mountainId,
    String routeFile,
  ) async {
    try {
      final path = '$_routesBasePath/$mountainId/rute/$routeFile';
      final json = await rootBundle.loadString(path);
      return MountainRoute.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('Failed to load route $routeFile for mountain $mountainId: $e');
      return null;
    }
  }
}
