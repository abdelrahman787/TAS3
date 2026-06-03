import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../matching/matching_engine.dart';

class UserPreferences {
  static const _kOnboardingSeen = 'onboarding_seen';
  static const _kDifficulty = 'difficulty';
  static const _kStoreAudio = 'store_audio';

  final SharedPreferences _prefs;
  UserPreferences(this._prefs);

  bool get onboardingSeen => _prefs.getBool(_kOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen(bool v) => _prefs.setBool(_kOnboardingSeen, v);

  DifficultyMode get difficulty {
    final name = _prefs.getString(_kDifficulty);
    return DifficultyMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => DifficultyMode.normal,
    );
  }

  Future<void> setDifficulty(DifficultyMode m) =>
      _prefs.setString(_kDifficulty, m.name);

  bool get storeAudio => _prefs.getBool(_kStoreAudio) ?? false;
  Future<void> setStoreAudio(bool v) => _prefs.setBool(_kStoreAudio, v);

  Future<void> clearAll() => _prefs.clear();
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final userPreferencesProvider = Provider<UserPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return UserPreferences(prefs);
});
