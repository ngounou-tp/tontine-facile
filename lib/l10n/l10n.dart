import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Langue de repli : l'app est née en français, et c'est la langue utilisée
/// si le téléphone n'est ni en français ni en anglais.
const fallbackLocale = Locale('fr');

/// Choisit la langue de l'app à partir des préférences du téléphone :
/// la première langue prise en charge (fr ou en), sinon le français.
Locale resolveAppLocale(Iterable<Locale>? preferences) {
  for (final locale in preferences ?? const <Locale>[]) {
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
  }
  return fallbackLocale;
}

/// Accès aux textes traduits hors de l'arbre de widgets (formatage des
/// montants et des dates, messages des exceptions). Mis à jour par
/// `DjanguiBookApp` à chaque changement de langue ; français par défaut
/// (tests unitaires, code exécuté avant le premier build).
abstract final class L10n {
  static AppLocalizations _current = lookupAppLocalizations(fallbackLocale);

  static AppLocalizations get current => _current;

  static void setLocale(Locale locale) {
    _current = lookupAppLocalizations(locale);
  }
}

extension AppLocalizationsContext on BuildContext {
  /// Textes traduits de l'écran courant. Repli sur [L10n.current] quand
  /// l'arbre ne fournit pas de délégué (widgets testés isolément dans un
  /// `MaterialApp` minimal).
  AppLocalizations get l10n => AppLocalizations.of(this) ?? L10n.current;
}
