/// Kelas model yang menyimpan parameter scaler untuk normalisasi data,
/// yaitu rata-rata (mean) dan standar deviasi (std) setiap fitur.
///
/// Digunakan saat memproses input ke model machine learning agar nilai
/// fitur berada dalam rentang yang diharapkan.
class ScalerModel {
  /// Daftar nilai rata-rata untuk setiap fitur.
  final List<double> mean;

  /// Daftar nilai standar deviasi untuk setiap fitur.
  final List<double> std;

  ScalerModel({required this.mean, required this.std});

  /// Membuat instance dari objek JSON (misalnya dari file scaler_params.json).
  factory ScalerModel.fromJson(Map<String, dynamic> json) {
    return ScalerModel(
      mean: List<double>.from(json['mean'] as List),
      std: List<double>.from(json['std'] as List),
    );
  }

  /// Konversi kembali ke format JSON agar bisa disimpan atau dikirim.
  Map<String, dynamic> toJson() {
    return {
      'mean': mean,
      'std': std,
    };
  }

  @override
  String toString() {
    // Representasi sederhana untuk logging/debugging
    return 'ScalerModel(mean: $mean, std: $std)';
  }
}
