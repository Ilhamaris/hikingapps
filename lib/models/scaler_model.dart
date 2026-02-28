/// Model class for holding scaler parameters (mean and std deviation)
class ScalerModel {
  final List<double> mean;
  final List<double> std;

  ScalerModel({required this.mean, required this.std});

  /// Create ScalerModel from JSON map
  factory ScalerModel.fromJson(Map<String, dynamic> json) {
    return ScalerModel(
      mean: List<double>.from(json['mean'] as List),
      std: List<double>.from(json['std'] as List),
    );
  }

  /// Convert ScalerModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'mean': mean,
      'std': std,
    };
  }

  @override
  String toString() {
    return 'ScalerModel(mean: $mean, std: $std)';
  }
}
