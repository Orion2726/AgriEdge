/// Model labels come in each training set's own convention
/// ("Potato___Late_blight", "bacterial_leaf_blight", "Yellow Rust"); show
/// them as plain words. Crop-prefixed labels keep only the disease part.
String prettyDiseaseLabel(String label) {
  final parts = label.split('___');
  final disease = parts.length > 1 ? parts.sublist(1).join(' ') : label;
  final words = disease.replaceAll('_', ' ').trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) return label;
  final text = words.join(' ').toLowerCase();
  return text[0].toUpperCase() + text.substring(1);
}
