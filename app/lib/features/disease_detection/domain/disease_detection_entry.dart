class DiseaseDetectionEntry {
  const DiseaseDetectionEntry({
    required this.id,
    required this.label,
    required this.confidence,
    required this.createdAt,
    required this.syncStatus,
    this.imagePath,
    this.lat,
    this.lng,
    this.consentShared = false,
    this.isMock = false,
  });

  final String id;
  final String label;
  final double confidence;
  final String? imagePath;
  final double? lat;
  final double? lng;
  final bool consentShared;
  final bool isMock;
  final DateTime createdAt;
  final String syncStatus;
}

class TreatmentAdvice {
  const TreatmentAdvice({
    required this.crop,
    required this.disease,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
  });

  factory TreatmentAdvice.fromJson(Map<String, dynamic> json) => TreatmentAdvice(
        crop: json['crop'] as String,
        disease: json['disease'] as String,
        symptoms: json['symptoms'] as String,
        treatment: json['treatment'] as String,
        prevention: json['prevention'] as String,
      );

  final String crop;
  final String disease;
  final String symptoms;
  final String treatment;
  final String prevention;
}
