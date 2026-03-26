// Kelas pendukung yang menyimpan informasi dasar tentang sebuah rute,
// termasuk nama yang ditampilkan dan nama file JSON yang berisi jalur.
class RouteInfo {
  /// Nama file JSON rute (misal "gunung_a_rute1.json").
  final String file;
  /// Nama rute yang ditampilkan ke pengguna.
  final String name;

  RouteInfo({
    required this.file,
    required this.name,
  });

  /// Buat RouteInfo dari map JSON (biasa dari daftar `routes` di file
  /// metadata utama).
  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      file: json['file'] ?? '',
      name: json['name'] ?? '',
    );
  }

  /// Konversi ke JSON.
  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'name': name,
    };
  }
}

/// Model untuk metadata lengkap sebuah gunung, termasuk daftar jalur yang
/// tersedia.
class MountainMetadata {
  /// Nama gunung.
  final String mountainName;
  /// Ketinggian puncak dalam meter.
  final int elevation;
  /// Provinsi atau wilayah administratif.
  final String province;
  /// Deskripsi teks yang menjelaskan gunung tersebut.
  final String description;
  /// Daftar informasi rute yang bisa diambil.
  final List<RouteInfo> routes;

  MountainMetadata({
    required this.mountainName,
    required this.elevation,
    required this.province,
    required this.description,
    required this.routes,
  });

  /// Buat objek dari JSON, misalnya saat memuat file `metadata.json`.
  factory MountainMetadata.fromJson(Map<String, dynamic> json) {
    final routesList = (json['routes'] as List?)
            ?.map((route) => RouteInfo.fromJson(route as Map<String, dynamic>))
            .toList() ??
        [];

    return MountainMetadata(
      mountainName: json['mountain_name'] ?? '',
      elevation: json['elevation'] ?? 0,
      province: json['province'] ?? '',
      description: json['description'] ?? '',
      routes: routesList,
    );
  }

  /// Konversikan metadata kembali ke Map agar bisa diserialisasi.
  Map<String, dynamic> toJson() {
    return {
      'mountain_name': mountainName,
      'elevation': elevation,
      'province': province,
      'description': description,
      'routes': routes.map((route) => route.toJson()).toList(),
    };
  }
}
