import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lighting.dart';
import '../models/user_profile.dart';

/// Everything personal lives here, on the device (Vision, chapter 17).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'profile_v1';
  static const _lightingsKey = 'lightings_v1';
  static const _flagsKey = 'flags_v1';
  static const _eventsKey = 'analytics_v1';

  UserProfile? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) =>
      _prefs.setString(_profileKey, jsonEncode(profile.toJson()));

  List<LightingRecord> loadLightings() {
    final raw = _prefs.getString(_lightingsKey);
    if (raw == null) return [];
    return [
      for (final e in jsonDecode(raw) as List)
        LightingRecord.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<void> saveLightings(List<LightingRecord> records) => _prefs.setString(
      _lightingsKey, jsonEncode([for (final r in records) r.toJson()]));

  Map<String, dynamic> _flags() {
    final raw = _prefs.getString(_flagsKey);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  bool flag(String name) => _flags()[name] == true;

  Future<void> setFlag(String name, [bool value = true]) {
    final f = _flags()..[name] = value;
    return _prefs.setString(_flagsKey, jsonEncode(f));
  }

  /// Counts events locally (Vision, chapter 35). Ready to forward to an
  /// analytics backend later; nothing leaves the device for now.
  Future<void> logEvent(String name, [Map<String, Object?> params = const {}]) {
    final raw = _prefs.getString(_eventsKey);
    final counts =
        raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
    final key = params.isEmpty
        ? name
        : '$name(${params.entries.map((e) => '${e.key}=${e.value}').join(',')})';
    counts[key] = ((counts[key] as int?) ?? 0) + 1;
    return _prefs.setString(_eventsKey, jsonEncode(counts));
  }

  Map<String, int> eventCounts() {
    final raw = _prefs.getString(_eventsKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }

  Future<void> clearAll() async {
    for (final k in [_profileKey, _lightingsKey, _flagsKey, _eventsKey]) {
      await _prefs.remove(k);
    }
  }
}
