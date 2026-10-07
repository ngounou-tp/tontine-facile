import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/application/onboarding_provider.dart';

/// Langue choisie explicitement dans Réglages, ou `null` pour suivre la
/// langue du téléphone. Persistée dans les préférences locales.
final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider)?.getString(_key);
    return code == null ? null : Locale(code);
  }

  /// [locale] `null` : revenir à la langue du téléphone.
  Future<void> setLocale(Locale? locale) async {
    final preferences = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await preferences?.remove(_key);
    } else {
      await preferences?.setString(_key, locale.languageCode);
    }
    state = locale;
  }
}
