/// Kelas model yang menyimpan hasil inferensi untuk setiap segmen
///
/// Aplikasi menggunakan data ini untuk menampilkan label yang diprediksi,
/// nilai prediksi sendiri, dan nilai kumulatif (misalnya total jarak atau
/// waktu) pada setiap bagian rute.
class SegmentResult {
  /// Label atau nama segmen (misalnya "pendakian curam").
  final String label;

  /// Nilai hasil prediksi untuk segmen ini (misal probabilitas atau skor).
  final double predicted;

  /// Nilai kumulatif sampai segmen ini, bisa berupa jarak atau waktu total.
  final double cumulative;

  SegmentResult({
    required this.label,
    required this.predicted,
    required this.cumulative,
  });

  @override
  String toString() {
    // Representasi string untuk debugging atau logging
    return 'SegmentResult(label: $label, predicted: $predicted, cumulative: $cumulative)';
  }
}
