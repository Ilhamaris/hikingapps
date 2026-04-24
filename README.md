# HikingApps

## Deskripsi Aplikasi

HikingApps adalah aplikasi mobile yang dirancang untuk membantu pendaki dalam merencanakan dan melacak aktivitas pendakian gunung mereka. Aplikasi ini menjawab tantangan dalam memperkirakan waktu pendakian dengan akurat, yang sangat penting untuk keselamatan dan perencanaan. Dengan memanfaatkan algoritma machine learning, aplikasi ini memberikan prediksi waktu yang dipersonalisasi berdasarkan parameter pengguna seperti berat badan, berat peralatan, dan karakteristik rute.

Aplikasi ini menyelesaikan masalah durasi pendakian yang tidak dapat diprediksi dengan menggabungkan faktor seperti perubahan elevasi, jarak, kemiringan, dan kondisi fisik individu. Ini memungkinkan pengguna untuk:
- Memilih dari rute gunung yang telah ditentukan sebelumnya
- Memasukkan parameter pribadi dan peralatan
- Menerima estimasi waktu berbasis ML untuk segmen rute
- Memvisualisasikan jalur di peta interaktif
- Melacak lokasi real-time selama pendakian
- Mempertahankan riwayat pendakian yang telah selesai

Aplikasi ini bekerja dengan pertama-tama memungkinkan pengguna memilih gunung dan rute tertentu. Pengguna kemudian memasukkan berat badan dan berat tas. Sistem memproses data rute (jarak, elevasi, kemiringan) melalui model regresi linier yang telah dilatih untuk memprediksi waktu pendakian segmen demi segmen. Hasil ditampilkan secara kumulatif, dan pengguna dapat melihat rute di peta berbasis OpenStreetMap dengan dukungan tile offline.

## Fitur Utama Aplikasi

### Pemilihan Gunung dan Rute
- Jelajahi gunung yang tersedia dengan detail (nama, lokasi, elevasi, deskripsi)
- Lihat rute pendakian yang tersedia untuk setiap gunung
- Akses metadata rute termasuk jarak dan waypoint

### Input Parameter untuk Estimasi
- Masukkan berat badan dan berat tas
- Validasi parameter input
- Persiapan data untuk pemrosesan ML

### Estimasi Waktu Berbasis Machine Learning
- Memprediksi waktu pendakian menggunakan model regresi linier TensorFlow Lite
- Mempertimbangkan 5 fitur kunci: berat badan, berat tas, delta jarak, delta elevasi, kemiringan
- Memberikan estimasi waktu segmen demi segmen dan kumulatif
- Menormalkan data input menggunakan parameter scaler yang telah dilatih sebelumnya

### Visualisasi Peta Interaktif
- Menampilkan jalur pendakian menggunakan flutter_map
- Integrasi tile OpenStreetMap untuk peta online
- Dukungan peta offline menggunakan format MBTiles
- Visualisasi rute dengan waypoint dan overlay jalur

### Pelacakan Lokasi Real-Time
- Pelacakan lokasi berbasis GPS selama pendakian
- Penanganan izin untuk akses lokasi
- Pembaruan posisi berkelanjutan dengan akurasi yang dapat dikonfigurasi

### Riwayat dan Statistik Pendakian
- Menyimpan catatan pendakian yang telah selesai
- Menampilkan riwayat dengan gunung, rute, tanggal, dan waktu estimasi
- Tampilan detail segmen pendakian dan kemajuan kumulatif

## Teknologi yang Digunakan

- **Flutter**: Framework mobile lintas platform untuk pengembangan UI
- **Dart**: Bahasa pemrograman untuk aplikasi Flutter
- **TensorFlow Lite**: Inferensi machine learning untuk prediksi waktu
- **flutter_map**: Library pemetaan open-source untuk Flutter
- **latlong2**: Penanganan koordinat latitude/longitude
- **geolocator**: Layanan lokasi GPS
- **permission_handler**: Manajemen izin runtime
- **shared_preferences**: Persistensi data lokal
- **flutter_native_splash**: Implementasi splash screen native
- **flutter_launcher_icons**: Pembuatan ikon aplikasi
- **uuid**: Pembuatan pengidentifikasi unik
- **OpenStreetMap**: Data peta gratis dan tile
- **MBTiles**: Penyimpanan tile peta offline berbasis SQLite

## Arsitektur Aplikasi

Aplikasi ini mengikuti arsitektur berlapis yang memisahkan kepentingan:

- **Lapisan Presentasi** (page/, widgets/): Menangani layar UI dan komponen yang dapat digunakan ulang
- **Lapisan Logika Bisnis** (services/): Berisi fungsionalitas inti seperti inferensi ML, layanan lokasi, dan pemuatan data
- **Lapisan Data** (models/): Mendefinisikan struktur data dan serialisasi
- **Lapisan Konfigurasi** (config/): Mengelola pengaturan aplikasi secara keseluruhan seperti penyedia tile peta

Alur data:
1. Pengguna memilih gunung dan rute dari aset yang telah ditentukan
2. Pengguna memasukkan berat badan dan berat tas
3. Data rute dimuat dan disegmentasi
4. Fitur setiap segmen (jarak, elevasi, kemiringan) diekstrak
5. Fitur dinormalkan menggunakan ScalerService
6. Fitur yang dinormalkan diberikan ke TFLiteService untuk inferensi
7. Prediksi dikumpulkan dan ditampilkan
8. Peta dirender menggunakan flutter_map dengan tile OSM
9. Pelacakan lokasi mengalirkan data GPS selama pendakian aktif

## Struktur Folder Proyek

```
lib/
├── config/
│   └── tile_config.dart          # Konfigurasi penyedia tile peta
├── models/
│   ├── bounding_box.dart         # Perhitungan bounding box geografis
│   ├── hiking_history.dart       # Struktur data pendakian yang telah selesai
│   ├── hiking_route.dart         # Definisi rute dengan waypoint
│   ├── mountain.dart             # Model informasi gunung
│   ├── mountain_metadata.dart    # Penanganan metadata gunung
│   ├── mountain_route.dart       # Hubungan gunung-rute
│   ├── route_point.dart          # Data titik rute individu
│   ├── scaler_model.dart         # Parameter normalisasi data ML
│   └── segment_result.dart       # Hasil prediksi ML
├── page/
│   ├── estimation_screen.dart    # Tampilan hasil estimasi waktu
│   ├── hiking_map_screen.dart    # Peta interaktif dengan overlay rute
│   ├── history_detail_screen.dart # Tampilan detail riwayat pendakian
│   ├── history_screen.dart       # Daftar pendakian yang telah selesai
│   ├── home_screen.dart          # Dasbor utama aplikasi
│   ├── input_parameter_screen.dart # Form input parameter pengguna
│   ├── mountain_list_screen.dart # Antarmuka pemilihan gunung
│   └── route_list_screen.dart    # Pemilihan rute untuk gunung yang dipilih
├── services/
│   ├── bounding_box_calculator.dart # Perhitungan geografis
│   ├── history_service.dart      # Persistensi data riwayat
│   ├── inference_service.dart    # Pra-pemrosesan dan inferensi ML
│   ├── location_service.dart     # Manajemen lokasi GPS
│   ├── mountain_loader.dart      # Pemuatan data gunung
│   ├── route_loader.dart         # Pemuatan data rute
│   ├── scaler_service.dart       # Normalisasi data
│   ├── tflite_service.dart       # Manajemen model TensorFlow Lite
│   └── tile_cache_status_service.dart # Caching tile peta
├── widgets/
│   ├── bottom_sheet_estimation.dart # Bottom sheet hasil estimasi
│   ├── estimation_bottom_sheet.dart # Tampilan estimasi alternatif
│   ├── mountain_card.dart        # Widget item daftar gunung
│   └── route_card.dart           # Widget kartu rute
└── main.dart                     # Titik masuk aplikasi

assets/
├── images/
│   ├── splashscreen.png          # Gambar splash screen
│   └── icon.png                  # Ikon aplikasi
├── models/
│   ├── linear_regression.tflite  # Model ML yang telah dilatih
│   └── scaler_params.json        # Parameter normalisasi
├── routes/
│   ├── glonggong/
│   │   ├── metadata.json         # Metadata gunung
│   │   └── rute/
│   │       ├── route_glonggong_mlaten.json
│   │       └── route_glonggong_mlaten2.json
│   └── mongkrang/
│       ├── metadata.json
│       └── rute/
│           └── [file rute]
└── tiles/                        # Tile peta offline (MBTiles)
```

## Deskripsi Kelas

### Model
- **Mountain**: Mewakili data gunung dengan id, nama, lokasi, elevasi, deskripsi, dan path gambar
- **HikingRoute**: Mendefinisikan struktur rute dengan id, nama, jarak, dan daftar waypoint
- **HikingHistory**: Menyimpan catatan pendakian yang telah selesai dengan info gunung/rute, tanggal, berat, dan hasil segmen
- **ScalerModel**: Berisi parameter normalisasi (mean, std) untuk penskalaan input ML
- **SegmentResult**: Menyimpan hasil prediksi segmen individu dengan total kumulatif
- **RouteSegment**: Mewakili segmen rute antara waypoint dengan waktu estimasi

### Layanan
- **InferenceService**: Layanan ML utama yang mengkoordinasikan pra-pemrosesan dan prediksi
- **TFLiteService**: Mengelola pemuatan model TensorFlow Lite dan eksekusi inferensi
- **LocationService**: Menangani izin GPS, lokasi saat ini, dan streaming posisi
- **HistoryService**: Mengelola persistensi riwayat pendakian menggunakan SharedPreferences
- **MountainLoader**: Memuat metadata gunung dan data rute dari aset
- **RouteLoader**: Memproses file JSON rute individu menjadi struktur data yang dapat digunakan
- **ScalerService**: Menerapkan normalisasi pada fitur input menggunakan parameter yang dimuat

### Halaman (Layar)
- **HomeScreen**: Dasbor utama dengan navigasi ke fitur
- **MountainListScreen**: Menampilkan gunung yang tersedia untuk pemilihan
- **RouteListScreen**: Menampilkan rute untuk gunung yang dipilih
- **InputParameterScreen**: Form untuk memasukkan berat badan dan berat tas
- **EstimationScreen**: Menampilkan waktu pendakian yang diprediksi ML
- **HikingMapScreen**: Tampilan peta interaktif dengan overlay rute dan pelacakan
- **HistoryScreen**: Tampilan daftar pendakian yang telah selesai
- **HistoryDetailScreen**: Tampilan detail catatan pendakian individu

### Widget
- **MountainCard**: Komponen kartu yang dapat digunakan ulang untuk item daftar gunung
- **RouteCard**: Komponen kartu untuk pemilihan rute
- **EstimationBottomSheet**: Bottom sheet yang menampilkan hasil estimasi

## Machine Learning

Aplikasi ini menggunakan model **Regresi Linier** yang diimplementasikan di TensorFlow Lite untuk memprediksi waktu pendakian.

**Tipe Model**: Regresi Linier
**Fitur Input** (5 fitur dalam urutan):
1. Berat badan (kg)
2. Berat tas (kg) 
3. Delta jarak (meter)
4. Delta elevasi (meter)
5. Kemiringan (derajat)

**Pemuatan Model**: Model dimuat dari `assets/models/linear_regression.tflite` menggunakan paket tflite_flutter. Singleton TFLiteService mengelola inisialisasi model dan inferensi.

**Proses Prediksi**:
1. Fitur mentah diekstrak dari data segmen rute
2. Fitur dinormalkan menggunakan ScalerService dengan mean dan standar deviasi yang telah dihitung sebelumnya
3. Fitur yang dinormalkan diberikan ke interpreter TFLite
4. Model mengeluarkan waktu yang diprediksi (dalam menit) untuk setiap segmen
5. Hasil dikumpulkan untuk waktu rute total

**Parameter Scaler**: Disimpan di `assets/models/scaler_params.json` dengan array mean dan std untuk setiap fitur.

## Sistem Peta dan Navigasi

**Peta Online**: Menggunakan flutter_map dengan tile OpenStreetMap dari `https://tile.openstreetmap.org/{z}/{x}/{y}.png`

**Peta Offline**: Mendukung format MBTiles yang disimpan di `assets/tiles/` untuk penggunaan offline

**Visualisasi Rute**: 
- Rute dimuat dari file JSON di `assets/routes/`
- Setiap rute berisi waypoint dengan koordinat lat/lon
- Jalur dirender sebagai polyline di peta
- Data elevasi dan kemiringan digunakan untuk prediksi ML

**Pelacakan Lokasi**:
- Pelacakan GPS real-time menggunakan paket geolocator
- Izin lokasi diminta melalui permission_handler
- Stream posisi dengan akurasi dan filter jarak yang dapat dikonfigurasi
- Lokasi saat ini ditampilkan di peta selama pelacakan aktif

## Cara Menjalankan Proyek

### Prasyarat
- Flutter SDK (^3.10.1)
- Dart SDK (termasuk dengan Flutter)
- Android Studio atau VS Code dengan ekstensi Flutter
- Perangkat Android/iOS atau emulator

### Langkah Instalasi
1. Klon repositori:
   ```bash
   git clone <repository-url>
   cd hikingapps
   ```

2. Instal dependensi:
   ```bash
   flutter pub get
   ```

3. Hasilkan ikon peluncur (opsional):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

### Build untuk Produksi
- **Android APK**:
  ```bash
  flutter build apk --release
  ```
- **iOS**:
  ```bash
  flutter build ios --release
  ```

## Tangkapan Layar atau Tampilan Contoh

Aplikasi ini menyertakan aset visual berikut:
- `assets/images/splashscreen.png`: Splash screen aplikasi
- `assets/images/icon.png`: Ikon peluncur aplikasi

Tangkapan layar contoh biasanya menunjukkan:
- Layar pemilihan gunung
- Visualisasi rute di peta
- Hasil estimasi waktu
- Daftar riwayat pendakian

## Pengembang

Dikembangkan sebagai aplikasi Flutter untuk estimasi waktu pendakian dan perencanaan rute.</content>
<parameter name="filePath">d:\Flutter\hikingapps\README.md
