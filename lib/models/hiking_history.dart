import 'dart:convert';

class HikingHistory {
  final String id;
  final String mountainName;
  final String routeName;
  final DateTime date;
  final Duration estimatedTime;
  final double bodyWeight;
  final double bagWeight;
  final List<RouteSegment> segments;

  HikingHistory({
    required this.id,
    required this.mountainName,
    required this.routeName,
    required this.date,
    required this.estimatedTime,
    required this.bodyWeight,
    required this.bagWeight,
    required this.segments,
  });

  /// Konversi objek menjadi Map JSON untuk penyimpanan atau pengiriman.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mountainName': mountainName,
      'routeName': routeName,
      'date': date.toIso8601String(),
      'estimatedTime': estimatedTime.inMinutes,
      'bodyWeight': bodyWeight,
      'bagWeight': bagWeight,
      'segments': segments.map((segment) => segment.toJson()).toList(),
    };
  }

  /// Buat HikingHistory dari Map JSON (misalnya saat membaca dari file).
  factory HikingHistory.fromJson(Map<String, dynamic> json) {
    return HikingHistory(
      id: json['id'] ?? '',
      mountainName: json['mountainName'] ?? '',
      routeName: json['routeName'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      estimatedTime: Duration(minutes: json['estimatedTime'] ?? 0),
      bodyWeight: (json['bodyWeight'] ?? 0.0).toDouble(),
      bagWeight: (json['bagWeight'] ?? 0.0).toDouble(),
      segments: (json['segments'] as List?)
          ?.map((segment) => RouteSegment.fromJson(segment))
          .toList() ?? [],
    );
  }

  /// Mendapatkan representasi JSON sebagai string.
  String toJsonString() => jsonEncode(toJson());
}

/// Subkelas yang menggambarkan satu segmen perjalanan antara dua titik.
class RouteSegment {
  final String from;
  final String to;
  final Duration estimatedTime;

  RouteSegment({
    required this.from,
    required this.to,
    required this.estimatedTime,
  });

  /// Konversi segmen ke Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'estimated_minutes': estimatedTime.inMinutes,
    };
  }

  /// Buat segmen dari Map JSON.
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      estimatedTime: Duration(minutes: json['estimated_minutes'] ?? 0),
    );
  }
}
