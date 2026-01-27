// Kelas untuk merepresentasikan data gunung
class Mountain {
  // Identitas unik gunung
  final String id;
  // Nama gunung
  final String name;
  // Lokasi atau wilayah di mana gunung berada
  final String location;
  // Ketinggian gunung dalam meter
  final double elevation;
  // Deskripsi detail tentang gunung
  final String description;
  // Jalur file ke gambar gunung
  final String imagePath;

  // Konstruktor untuk menginisialisasi semua properti gunung
  Mountain({
    required this.id,
    required this.name,
    required this.location,
    required this.elevation,
    required this.description,
    required this.imagePath,
  });
}
