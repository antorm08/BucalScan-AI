class PredictionImageInput {
  final String imagePath;
  final String? patientId;
  final String? patientName;
  final bool consentToStore;

  const PredictionImageInput({
    required this.imagePath,
    required this.consentToStore,
    this.patientId,
    this.patientName,
  });
}
