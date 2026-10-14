import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which crops this farmer grows — feeds the relevance engine's crop-match
/// term (§4). Doesn't exist as a concept anywhere else in the app yet; kept
/// deliberately tiny (a local preference, not a synced profile) since
/// nothing server-side needs it.
class FarmerProfile {
  FarmerProfile(this._prefs);

  final SharedPreferences _prefs;
  static const _cropIdsKey = 'p2p_farmer_crop_ids';

  List<String> get myCropIds => _prefs.getStringList(_cropIdsKey) ?? const [];

  Future<void> setMyCropIds(List<String> cropIds) {
    return _prefs.setStringList(_cropIdsKey, cropIds);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final farmerProfileProvider = FutureProvider<FarmerProfile>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FarmerProfile(prefs);
});
