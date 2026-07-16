import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';

List<LesionEvaluation> comparableEvaluations(
  Iterable<LesionEvaluation> evaluations,
) {
  final comparable = evaluations
      .where(
        (evaluation) =>
            evaluation.image != null && evaluation.prediction != null,
      )
      .toList();
  comparable.sort((left, right) {
    final byDate = left.evaluatedAt.compareTo(right.evaluatedAt);
    return byDate != 0 ? byDate : left.id.compareTo(right.id);
  });
  return comparable;
}

class LesionComparisonPair {
  final LesionEvaluation left;
  final LesionEvaluation right;

  LesionComparisonPair({required this.left, required this.right})
    : assert(left.id != right.id);

  factory LesionComparisonPair.latest(List<LesionEvaluation> evaluations) {
    final comparable = comparableEvaluations(evaluations);
    if (comparable.length < 2) {
      throw ArgumentError('At least two comparable evaluations are required.');
    }
    return LesionComparisonPair(
      left: comparable[comparable.length - 2],
      right: comparable.last,
    );
  }

  LesionComparisonPair selectLeft(LesionEvaluation evaluation) =>
      evaluation.id == right.id
      ? LesionComparisonPair(left: evaluation, right: left)
      : LesionComparisonPair(left: evaluation, right: right);

  LesionComparisonPair selectRight(LesionEvaluation evaluation) =>
      evaluation.id == left.id
      ? LesionComparisonPair(left: right, right: evaluation)
      : LesionComparisonPair(left: left, right: evaluation);
}

double percentagePointDelta(double left, double right) => (right - left) * 100;

double malignantOutput(LesionEvaluation evaluation) =>
    evaluation.prediction?.probabilities['malignant'] ?? 0;
