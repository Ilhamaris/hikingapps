**Context**
I'm building a Flutter app for mountain climbing.
I want to add an app that uses **OpenStreetMap + flutter_map** and must support **offline maps** by **downloading tiles after the user selects a hiking trail (GPX)** and then caching them.

Framework & tools:

* flutter_map
* flutter_map_tile_caching
* GPX files are stored in `assets/gpx/`

---

### TASK 1 — Parse GPX

Create Flutter code to:

* Read a GPX file from `assets/gpx`
* Extract all trackpoints (latitude & longitude)
* Generate a `List<LatLng>`

Use a clean and reusable code structure.

---

### TASK 2 — Calculate the Path Bounding Box

From `List<LatLng>`, GPX results:

* Calculate:

* north (maximum latitude)
* south (minimum latitude)
* east (maximum longitude)
* west (minimum longitude)
* Add a buffer area ±500 meters from the bounding box

The output is a bounding box object ready to be used for downloading tiles.

---

### TASK 3 — Tile Cache Initialization

Implement the `flutter_map_tile_caching` initialization:

* Create a cache store named `"jalurCache"`
* Initialization is done in `main()` before `runApp()`
* Ensure the cache is stored in internal storage (not assets)

---

### TASK 4 — Download Tiles Based on Route

Create a function:

```dart
Future<void> downloadTilesForRoute(BoundingBox box)
```

The function must:

* Use `flutter_map_tile_caching`
* Download tiles based on the bounding box
* Use zoom levels:

* minZoom: 14
* maxZoom: 16
* Run **only once after the user selects a route**

Add a short explanatory comment to the code.

---

### TASK 5 — Path Cache Status

Add a simple mechanism:

* Store the status of whether a tile for a path has been downloaded.
* Use the path identifier (e.g., GPX file name).
* Can use SharedPreferences or a simple local mechanism.

Goal: Prevent repeated downloads.

---

### TASK 6 — Display a Map Using a Cache

Implement `FlutterMap` with:

* `TileLayer` using `TileProvider` from the cache.
* Normal mode: online + cache.
* Tracking mode: `offlineOnly = true.`

Separate the TileLayer configuration for easy mode switching.

---

### TASK 7 — UI Flow

Implement the following flow:

1. User selects a hiking trail
2. System:

* Parse GPX
* Calculate bounding box
* Check cache status
3. If no cache exists:

* Start downloading tiles
* Show a loading indicator
4. When finished:

* Mark the trail as “offline ready”
* Show the map

---

### CONSTRAINTS

* Do not download tiles in the map page's `initState`
* Do not hardcode bounding boxes
* Do not store tiles in the `assets` folder
* Code should be modular and easily testable
* Focus on a stable architecture, not shortcuts

---

### EXPECTED OUTPUT

* Separate files/classes for:

* GPX parser
* Bounding box calculator
* Tile downloader
* Map screen