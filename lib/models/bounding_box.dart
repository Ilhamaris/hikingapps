import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// batas area geografis
class BoundingBox {
  final double north;
  final double south;
  final double east;
  final double west;

  BoundingBox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  // Getter untuk mendapatkan latitude center
  double get centerLat => (north + south) / 2;

  // Getter untuk mendapatkan longitude center
  double get centerLon => (east + west) / 2;

  // Getter untuk mendapatkan lebar area dalam derajat
  double get width => east - west;

  // Getter untuk mendapatkan tinggi area dalam derajat
  double get height => north - south;

 // membuat kotak LatLngBounds dari BoundingBox
  LatLngBounds toLatLngBounds() {
    return LatLngBounds(
      LatLng(south, west),
      LatLng(north, east),
    );
  }

  @override
  String toString() =>
      'BoundingBox(N: $north, S: $south, E: $east, W: $west)';
}
