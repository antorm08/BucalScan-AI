class PredictionImageInput {
  final String imagePath;
  final String? patientId;
  final String? patientName;

  const PredictionImageInput({
    required this.imagePath,
    this.patientId,
    this.patientName,
  });
}
