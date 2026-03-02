// Model untuk merepresentasikan metadata gunung dari JSON
class RouteInfo {
  final String file;
  final String name;

  RouteInfo({
    required this.file,
    required this.name,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      file: json['file'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'name': name,
    };
  }
}

class MountainMetadata {
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
