import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/route_point.dart';

class RouteLoader {
  static Future<List<RoutePoint>> loadRoute(String path) async {
    final raw = await rootBundle.loadString(path);
    final List data = jsonDecode(raw);
    return data.map((e) => RoutePoint.fromJson(e)).toList();
  }
}
