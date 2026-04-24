// Kelas pendukung yang menyimpan informasi dasar tentang sebuah rute,
// termasuk nama yang ditampilkan dan nama file JSON yang berisi jalur.
class RouteInfo {
  /// Nama file JSON rute (misal "gunung_a_rute1.json").
  final String file;

  /// Nama rute yang ditampilkan ke pengguna.
  final String name;

  /// Kontak person untuk rute tersebut.
  final String? contactPerson;

  RouteInfo({required this.file, required this.name, this.contactPerson});

  /// Buat RouteInfo dari map JSON (biasa dari daftar `routes` di file
  /// metadata utama).
  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      file: json['file'] ?? '',
      name: json['name'] ?? '',
      contactPerson: json['contact_person'] as String?,
    );
  }

  /// Konversi ke JSON.
  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'name': name,
      if (contactPerson != null) 'contact_person': contactPerson,
    };
  }
}

/// Model untuk metadata lengkap sebuah gunung, termasuk daftar jalur yang
/// tersedia.
class MountainMetadata {
  /// Nama gunung.
  final String mountainName;
 
  final int elevation;

  final String province;

  final String description;

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
    final routesList =
        (json['routes'] as List?)
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
