import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Régions disponibles (Algérie en priorité car contexte du PFE).
enum AppRegion {
  algerie('DZ', 'Algérie', '🇩🇿'),
  france('FR', 'France', '🇫🇷'),
  maroc('MA', 'Maroc', '🇲🇦'),
  tunisie('TN', 'Tunisie', '🇹🇳'),
  belgique('BE', 'Belgique', '🇧🇪'),
  suisse('CH', 'Suisse', '🇨🇭'),
  canada('CA', 'Canada', '🇨🇦'),
  autre('OT', 'Autre', '🌍');

  final String code;
  final String label;
  final String flag;
  const AppRegion(this.code, this.label, this.flag);

  static AppRegion fromCode(String? code) =>
      AppRegion.values.firstWhere((r) => r.code == code,
          orElse: () => AppRegion.algerie);
}

/// Langues supportées par l'application.
enum AppLanguage {
  francais('fr', 'Français', '🇫🇷'),
  anglais('en', 'English', '🇬🇧');

  final String code;
  final String label;
  final String flag;
  const AppLanguage(this.code, this.label, this.flag);

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) =>
      AppLanguage.values.firstWhere((l) => l.code == code,
          orElse: () => AppLanguage.francais);
}

/// État global des préférences utilisateur (région + langue).
class UserPreferences {
  final AppRegion region;
  final AppLanguage language;

  const UserPreferences({
    this.region = AppRegion.algerie,
    this.language = AppLanguage.francais,
  });

  UserPreferences copyWith({AppRegion? region, AppLanguage? language}) =>
      UserPreferences(
        region: region ?? this.region,
        language: language ?? this.language,
      );
}

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(const UserPreferences()) {
    _load();
  }

  static const _kRegion = 'pref_region';
  static const _kLang = 'pref_language';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = UserPreferences(
      region: AppRegion.fromCode(prefs.getString(_kRegion)),
      language: AppLanguage.fromCode(prefs.getString(_kLang)),
    );
  }

  Future<void> setRegion(AppRegion region) async {
    state = state.copyWith(region: region);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRegion, region.code);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, language.code);
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>(
        (ref) => UserPreferencesNotifier());
