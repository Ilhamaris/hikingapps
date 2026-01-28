// Kelas untuk merepresentasikan data gunung
class Mountain {
  final String id;
  final String name;
  final String location;
  final double elevation;
  final String description;
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
