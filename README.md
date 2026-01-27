> **Role**
> You are a senior Flutter mobile engineer specialized in offline map and outdoor navigation apps.

> **Objective**
> Build a **Flutter mobile application** that visually matches the provided hiking app screenshots and **displays an offline map with a hiking trail loaded from a GPX file**.

---

## 1️⃣ Tech Stack (STRICT – DO NOT CHANGE)

* Framework: **Flutter**
* Language: **Dart**
* State management: **basic (StatefulWidget / ChangeNotifier-ready)**
* Map library: **flutter_map**
* Offline tiles: **MBTiles**
* GPX parsing: **gpx package**
* Location: **geolocator**
* Storage: **local assets / local file system**

❌ Do NOT use Google Maps
❌ Do NOT require internet connection
❌ Do NOT use Mapbox API

---

## 2️⃣ Map & GPX Requirements (CORE FEATURE)

* Load **offline map tiles (MBTiles)** from local storage
* Display map using **flutter_map**
* Load a **GPX file from assets**
* Parse GPX:

  * Track points → polyline
  * Waypoints → markers (Pos, Puncak)
* Render:

  * GPX track as **dashed polyline**
  * Waypoints as labeled markers
* Show **current GPS position**
* All map features must work **offline**

---

## 3️⃣ Screen Flow (MATCH THE UI)

### 🏠 Home Screen

* Title: *Prediksi Waktu Pendakian*
* Two cards:

  * Informasi Jalur Pendakian
  * Riwayat Pendakian

---

### 🏔️ Informasi Gunung

* Search bar (UI only)
* List of mountains (mock data)
* Button: **Pilih Jalur**

---

### 🥾 Pilih Jalur Pendakian

* List of hiking routes
* Each route links to a **specific GPX file**

---

### 🧍 Input Parameter

* Berat Badan (kg)
* Berat Tas (kg)
* Button: **Mulai Pendakian**

---

### 🗺️ Peta Pendakian (IMPORTANT)

* Full-screen offline map
* Display:

  * GPX hiking route
  * Pos-pos pendakian
  * Puncak
  * Current user location
* Bottom sheet:

  * Estimasi waktu ke pos (mock values)
* Floating buttons:

  * Center location
  * Compass (UI only)

---

### ⏱️ Selesaikan Pendakian Dialog

* Modal confirmation
* Save dummy hiking data

---

### 📜 Riwayat Pendakian

* List of past hikes (mock)

---

### 📊 Detail Riwayat

* Segment-by-segment time breakdown

---

## 4️⃣ UI Design Rules (MATCH SCREENSHOTS)

* Primary color: **Green**
* Rounded cards
* Soft shadows
* Bottom sheet on map screen
* Clean outdoor navigation aesthetic
* One screen = one widget file

---

## 5️⃣ Code Structure (MANDATORY)

```
lib/
 ├─ main.dart
 ├─ screens/
 │   ├─ home_screen.dart
 │   ├─ mountain_list_screen.dart
 │   ├─ route_list_screen.dart
 │   ├─ input_parameter_screen.dart
 │   ├─ hiking_map_screen.dart
 │   ├─ history_screen.dart
 │   └─ history_detail_screen.dart
 ├─ widgets/
 │   ├─ mountain_card.dart
 │   ├─ route_card.dart
 │   └─ bottom_sheet_estimation.dart
 ├─ models/
 │   ├─ mountain.dart
 │   ├─ hiking_route.dart
 │   └─ hiking_history.dart
 └─ services/
     ├─ gpx_service.dart
     └─ location_service.dart
```

---

## 6️⃣ Explicit Constraints (DO NOT BREAK)

* No online map tiles
* No API calls
* No automatic route generation
* GPX is the **single source of truth** for hiking paths

---

## 7️⃣ Deliverables

* Fully working Flutter app
* Offline map visible
* GPX trail rendered
* UI matches provided screenshots
* Clear comments on:

  * GPX parsing
  * Offline map setup