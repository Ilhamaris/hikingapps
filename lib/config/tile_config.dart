/// Configuration for map tile providers and online tile serving
class TileConfig {
  /// OpenStreetMap tile endpoint
  /// Free and open-source tile source requiring no API key
  static const String openStreetMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// User agent for tile requests
  static const String userAgent = 'hikingapps/1.0';
}
