class PredictionImageInput {
  final String imagePath;
  final String? patientId;
  final String? patientName;
  final bool consentToStore;
  final String? lesionId;

  const PredictionImageInput({
    required this.imagePath,
    required this.consentToStore,
    this.patientId,
    this.patientName,
    this.lesionId,
  });
}
