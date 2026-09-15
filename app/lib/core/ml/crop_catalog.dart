class CropInfo {
  const CropInfo({required this.id, required this.displayName});

  /// Matches the asset subfolder name (assets/ml/disease/{id}/), the
  /// downloaded-model subfolder name, and the backend route segment
  /// (/api/models/disease/{id}).
  final String id;
  final String displayName;
}

/// Every crop with a disease-detection model, bundled or downloadable.
/// This is the single source of truth the crop picker, sync settings
/// screen, and ModelManager all iterate over.
const List<CropInfo> cropCatalog = [
  CropInfo(id: 'potato', displayName: 'Potato'),
  CropInfo(id: 'cotton', displayName: 'Cotton'),
  CropInfo(id: 'rice', displayName: 'Rice'),
  CropInfo(id: 'wheat', displayName: 'Wheat'),
  CropInfo(
    id: 'staple_crops',
    displayName: 'Staple crops (Corn, Potato, Rice, Sugarcane, Wheat)',
  ),
];
