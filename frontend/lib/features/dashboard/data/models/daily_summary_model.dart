import 'package:bucalscan_ai/features/dashboard/domain/entities/daily_summary.dart';

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

  DailySummary toEntity() {
    DateTime? parsedLatestAnalysisAt;
    final rawLatestAnalysisAt = latestAnalysisAt;
    if (rawLatestAnalysisAt != null && rawLatestAnalysisAt.isNotEmpty) {
      parsedLatestAnalysisAt = DateTime.tryParse(rawLatestAnalysisAt);
    }

    return DailySummary(
      total: total,
      benign: benign,
      malignant: malignant,
      latestAnalysisAt: parsedLatestAnalysisAt,
    );
  }
}
