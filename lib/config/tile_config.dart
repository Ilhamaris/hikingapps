/// Konfigurasi untuk penyedia peta dan penyajian daring.
class TileConfig {
  /// OpenStreetMap tile endpoint
  /// Sumber kode peta gratis dan sumber terbuka yang tidak memerlukan kunci API.
  static const String openStreetMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Pengguna untuk permintaan peta
  static const String userAgent = 'hikingapps/1.0';
}
