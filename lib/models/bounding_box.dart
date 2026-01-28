// Model untuk merepresentasikan bounding box dari area geografis
class BoundingBox {
  // Batas utara (latitude maksimum)
  final double north;
  // Batas selatan (latitude minimum)
  final double south;
  // Batas timur (longitude maksimum)
  final double east;
  // Batas barat (longitude minimum)
  final double west;

  // Konstruktor untuk menginisialisasi bounding box
  BoundingBox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  // Getter untuk mendapatkan latitude center
  double get centerLat => (north + south) / 2;

  // Getter untuk mendapatkan longitude center
  double get centerLon => (east + west) / 2;

  // Getter untuk mendapatkan lebar area dalam derajat
  double get width => east - west;

  // Getter untuk mendapatkan tinggi area dalam derajat
  double get height => north - south;

  @override
  String toString() =>
      'BoundingBox(N: $north, S: $south, E: $east, W: $west)';
}
