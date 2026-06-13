class DailySummary {
  final int total;
  final int benign;
  final int malignant;
  final DateTime? latestAnalysisAt;

  const DailySummary({
    required this.total,
    required this.benign,
    required this.malignant,
    this.latestAnalysisAt,
  });
}
