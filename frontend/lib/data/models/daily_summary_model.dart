class DailySummaryModel {
  final int total;
  final int benign;
  final int malignant;
  final String? latestAnalysisAt;

  const DailySummaryModel({
    required this.total,
    required this.benign,
    required this.malignant,
    this.latestAnalysisAt,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      total: json['total'] as int? ?? 0,
      benign: json['benign'] as int? ?? 0,
      malignant: json['malignant'] as int? ?? 0,
      latestAnalysisAt: json['latest_analysis_at'] as String?,
    );
  }
}
