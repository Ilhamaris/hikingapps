# Cobamaps - GPX Route Viewer

A Flutter application that loads and displays GPX files on an interactive map with polylines, auto-fit camera, and waypoint markers.

## Project Architecture

This project demonstrates a production-quality approach to displaying routes with typed waypoints. It follows separation of concerns: domain models, pure functions for logic, and stateful widgets for UI.

---

## Implementation Steps

### Step 1: Project Setup & Dependencies

**pubspec.yaml**
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^6.1.0
  latlong2: ^0.9.1
  gpx: ^2.2.0
  file_picker: ^8.0.0
  xml: ^6.5.0

flutter:
  uses-material-design: true
  assets:
    - assets/
```

**What each package does:**
- `flutter_map` - Interactive map rendering
- `latlong2` - Latitude/Longitude type with utilities
- `xml` - GPX file parsing
- `latlong2` - Provides `LatLngBounds` for camera fitting

---

### Step 2: Load GPX File from Assets

**Function: `loadGpxRoute()`**

```dart
Future<List<LatLng>> loadGpxRoute() async {
  final gpxString = await rootBundle.loadString('assets/Bukit_Mongkrang.gpx');
  final document = xml.XmlDocument.parse(gpxString);
  
  final points = <LatLng>[];
  final trkpts = document.findAllElements('trkpt');
  
  for (final trkpt in trkpts) {
    final lat = double.parse(trkpt.getAttribute('lat')!);
    final lon = double.parse(trkpt.getAttribute('lon')!);
    points.add(LatLng(lat, lon));
  }
  
  return points;
}
```

**How it works:**
1. Load GPX file as string from assets
2. Parse XML document
3. Find all `<trkpt>` elements (track points)
4. Extract `lat` and `lon` attributes
5. Convert to `LatLng` objects

**GPX Structure:**
```xml
<gpx>
  <trk>
    <trkseg>
      <trkpt lat="-7.67102" lon="111.18472">
        <ele>1767.01</ele>
      </trkpt>
      <!-- More points... -->
    </trkseg>
  </trk>
</gpx>
```

---

### Step 3: Calculate Bounding Box for Auto-Fit

**Function: `calculateBounds()`**

```dart
LatLngBounds calculateBounds(List<LatLng> points) {
  if (points.isEmpty) {
    throw Exception('Cannot calculate bounds for empty point list');
  }
  
  double minLat = points[0].latitude;
  double maxLat = points[0].latitude;
  double minLon = points[0].longitude;
  double maxLon = points[0].longitude;
  
  for (final point in points) {
    minLat = point.latitude < minLat ? point.latitude : minLat;
    maxLat = point.latitude > maxLat ? point.latitude : maxLat;
    minLon = point.longitude < minLon ? point.longitude : minLon;
    maxLon = point.longitude > maxLon ? point.longitude : maxLon;
  }
  
  return LatLngBounds(
    LatLng(minLat, minLon),
    LatLng(maxLat, maxLon),
  );
}
```

**Purpose:** Creates a geographic rectangle encompassing all route points. Used by `fitCamera()` to calculate optimal zoom level automatically.

---

### Step 4: Define Domain Model for Waypoints

**Enum & Class**

```dart
enum WaypointType { pos, puncak }

class Waypoint {
  final LatLng point;
  final WaypointType type;
  final String name;

  Waypoint({
    required this.point,
    required this.type,
    required this.name,
  });
}
```

**Why separate from LatLng:**
- Type-safe waypoint handling
- Decouples UI from business logic
- Enables icon/color mapping based on type

---

### Step 5: Create Sample Waypoint Data

**Module-level variable:**

```dart
final List<Waypoint> sampleWaypoints = [
  Waypoint(
    point: LatLng(-7.67102, 111.18472),
    type: WaypointType.pos,
    name: 'Base Camp',
  ),
  Waypoint(
    point: LatLng(-7.68899, 111.18622),
    type: WaypointType.puncak,
    name: 'Mongkrang Peak',
  ),
  Waypoint(
    point: LatLng(-7.67585, 111.18432),
    type: WaypointType.pos,
    name: 'Rest Point',
  ),
];
```

**For production:** Replace with dynamic data from GPX parsing or network.

---

### Step 6: Icon & Color Mapping

**Pure functions (outside build methods)**

```dart
IconData getWaypointIcon(WaypointType type) {
  switch (type) {
    case WaypointType.pos:
      return Icons.location_on;
    case WaypointType.puncak:
      return Icons.flag;
  }
}

Color getWaypointColor(WaypointType type) {
  switch (type) {
    case WaypointType.pos:
      return Colors.orange;
    case WaypointType.puncak:
      return Colors.purple;
  }
}
```

**Benefits:**
- Logic independent of widgets
- Easy to test and modify
- Reusable across components

---

### Step 7: Stateful Widget with MapController

**Root widget:**

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
```

**Why MapController:**
- Required to call `fitCamera()` programmatically
- Enables pan/zoom control
- Must be disposed to prevent memory leaks

---

### Step 8: Load Data with FutureBuilder

**In build method:**

```dart
FutureBuilder<List<LatLng>>(
  future: loadGpxRoute(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(child: Text('No route data found'));
    }
    
    final route = snapshot.data!;
    // Build map here
  },
)
```

**Pattern:**
1. Display spinner while loading
2. Handle errors gracefully
3. Validate data before rendering
4. Proceed with UI

---

### Step 9: Auto-Fit Camera (Post-Frame Callback)

**Critical for correct camera fitting:**

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final bounds = calculateBounds(route);
  mapController.fitCamera(
    CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(100),
    ),
  );
});
```

**Why post-frame callback is required:**
- Map widget must be fully laid out before fitting
- Uninitialized dimensions would cause incorrect zoom calculation
- Callback executes after frame rendering completes
- Camera fit then uses actual render context

---

### Step 10: Build FlutterMap with Layers

**Layer order (bottom to top):**

```dart
FlutterMap(
  mapController: mapController,
  options: const MapOptions(
    initialCenter: LatLng(0, 0),
    initialZoom: 1,
  ),
  children: [
    // Layer 1: Base tile map
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.app',
    ),

    // Layer 2: Route polyline
    PolylineLayer(
      polylines: [
        Polyline(
          points: route,
          strokeWidth: 4,
          color: Colors.red,
        ),
      ],
    ),

    // Layer 3: Waypoint markers
    MarkerLayer(
      markers: [
        for (final waypoint in sampleWaypoints)
          Marker(
            point: waypoint.point,
            width: 60,
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getWaypointColor(waypoint.type),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    getWaypointIcon(waypoint.type),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    waypoint.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  ],
)
```

**Layer breakdown:**
- **TileLayer**: OSM base map tiles
- **PolylineLayer**: Red route line connecting all GPX points
- **MarkerLayer**: Type-specific icons + labels for waypoints

---

## Quick Reference for Other Projects

### Minimal Setup (Just Map + Polyline)

```dart
// 1. Dependencies
flutter_map: ^6.1.0
latlong2: ^0.9.1

// 2. Load points
final route = await loadGpxRoute();

// 3. Calculate bounds
final bounds = calculateBounds(route);

// 4. Fit camera
mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(100)));

// 5. Render
FlutterMap(
  mapController: mapController,
  children: [
    TileLayer(urlTemplate: '...'),
    PolylineLayer(polylines: [Polyline(points: route, color: Colors.red)]),
  ],
)
```

### Adding Waypoints

1. Define enum for types: `enum WaypointType { start, end, checkpoint }`
2. Create class: `class Waypoint { LatLng point; WaypointType type; String name; }`
3. Add mapping functions: `getWaypointIcon()`, `getWaypointColor()`
4. Render in `MarkerLayer` with icon/color from mappings

---

## File Structure

```
lib/
  main.dart          // Main app + all logic
  
assets/
  *.gpx              // GPS track files
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Map shows blank white screen | Check initialZoom, ensure assets/ in pubspec.yaml |
| Camera doesn't fit route | Use post-frame callback, don't call fitCamera immediately |
| Polyline not visible | Check layer order (PolylineLayer above TileLayer) |
| Markers appear under polyline | Ensure MarkerLayer is last (top) in children list |
| GPX not loading | Verify file in assets/, restart flutter run |

---

## Production Checklist

- [ ] Replace hardcoded waypoints with GPX parsing
- [ ] Add error handling for malformed GPX
- [ ] Implement waypoint selection (onTap)
- [ ] Add route statistics (distance, elevation)
- [ ] Cache loaded routes in local storage
- [ ] Add offline map support
- [ ] Test with multiple GPX files