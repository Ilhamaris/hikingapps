/// Model class for storing inference results for each segment
class SegmentResult {
  final String label;
  final double predicted;
  final double cumulative;

  SegmentResult({
    required this.label,
    required this.predicted,
    required this.cumulative,
  });

  @override
  String toString() {
    return 'SegmentResult(label: $label, predicted: $predicted, cumulative: $cumulative)';
  }
}
