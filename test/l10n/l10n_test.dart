import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tontinefacile/app/locale_controller.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/core/utils/amount_formatter.dart';
import 'package:tontinefacile/core/utils/date_formatter.dart';
import 'package:tontinefacile/domain/enums/jour_semaine.dart';
import 'package:tontinefacile/domain/enums/occurrence_mensuelle.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/onboarding/application/onboarding_provider.dart';
import 'package:tontinefacile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:tontinefacile/l10n/domain_labels.dart';
import 'package:tontinefacile/l10n/l10n.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _placeholders(String message) => {
      ...RegExp(r'\{(\w+)\}').allMatches(message).map((m) => m.group(1)!),
      ...RegExp(r'\{(\w+),\s*(?:plural|select)').allMatches(message).map((m) => m.group(1)!),
    };

void main() {
  tearDown(() => L10n.setLocale(fallbackLocale));

  group('fichiers ARB', () {
    final fr = _arb('fr');
    final en = _arb('en');
    final cles = fr.keys.where((k) => !k.startsWith('@')).toSet();

    test('chaque texte français a sa traduction anglaise, et inversement', () {
      final clesEn = en.keys.where((k) => !k.startsWith('@')).toSet();
      expect(cles.difference(clesEn), isEmpty, reason: 'manquantes en anglais');
      expect(clesEn.difference(cles), isEmpty, reason: 'inconnues du modèle français');
    });

    test('les variables sont les mêmes dans les deux langues', () {
      for (final cle in cles) {
        expect(
          _placeholders(en[cle] as String),
          _placeholders(fr[cle] as String),
          reason: 'variables différentes pour « $cle »',
        );
      }
    });

    test('aucune traduction vide', () {
      for (final cle in cles) {
        expect((fr[cle] as String).trim(), isNotEmpty, reason: cle);
        expect((en[cle] as String).trim(), isNotEmpty, reason: cle);
      }
    });
  });

  group('choix de la langue', () {
    test('suit le téléphone en français ou en anglais', () {
      expect(resolveAppLocale(const [Locale('en', 'GB')]), const Locale('en'));
      expect(resolveAppLocale(const [Locale('fr', 'CM')]), const Locale('fr'));
    });

    test("prend la première langue prise en charge dans l'ordre du téléphone", () {
      expect(resolveAppLocale(const [Locale('de'), Locale('en'), Locale('fr')]), const Locale('en'));
    });

    test('se replie sur le français sinon', () {
      expect(resolveAppLocale(const [Locale('de'), Locale('pt')]), const Locale('fr'));
      expect(resolveAppLocale(null), const Locale('fr'));
    });

    test('le choix manuel est mémorisé, et peut revenir à la langue du téléphone', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      expect(container.read(localeControllerProvider), isNull);
      await container.read(localeControllerProvider.notifier).setLocale(const Locale('en'));
      expect(container.read(localeControllerProvider), const Locale('en'));

      final relance = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(relance.dispose);
      expect(relance.read(localeControllerProvider), const Locale('en'));

      await relance.read(localeControllerProvider.notifier).setLocale(null);
      expect(relance.read(localeControllerProvider), isNull);
    });
  });

  group('formats selon la langue', () {
    test('montants : espace insécable en français, virgule en anglais', () {
      expect(formatAmount(150000), '150\u00a0000\u00a0FCFA');
      L10n.setLocale(const Locale('en'));
      expect(formatAmount(150000), '150,000\u00a0FCFA');
      expect(formatAmount(-2500), '-2,500\u00a0FCFA');
    });

    test('dates', () {
      final date = DateTime(2026, 1, 10);
      expect(formatDate(date), '10 janv. 2026');
      expect(formatDateCourte(date), 'sam. 10 janv.');
      L10n.setLocale(const Locale('en'));
      expect(formatDate(date), 'Jan 10, 2026');
      expect(formatDateCourte(date), 'Sat, Jan 10');
    });

    test('échéances relatives, au singulier comme au pluriel', () {
      final aujourdhui = DateTime(2026, 3, 1);
      L10n.setLocale(const Locale('en'));
      expect(formatEcheanceRelative(DateTime(2026, 3, 2), maintenant: aujourdhui), 'tomorrow');
      expect(formatEcheanceRelative(DateTime(2026, 3, 6), maintenant: aujourdhui), 'in 5 days');
      expect(formatEcheanceRelative(DateTime(2026, 2, 27), maintenant: aujourdhui), '2 days ago');
    });

    test('périodicités en phrase', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      final en = lookupAppLocalizations(const Locale('en'));
      const hebdo = RegleChaqueSemaine(JourSemaine.lundi);
      const mensuel = RegleChaqueMoisSemaine(OccurrenceMensuelle.dernier, JourSemaine.vendredi);
      expect(periodiciteLabel(hebdo, fr), 'Chaque lundi');
      expect(periodiciteLabel(hebdo, en), 'Every Monday');
      expect(periodiciteLabel(mensuel, fr), 'Dernier vendredi du mois');
      expect(periodiciteLabel(mensuel, en), 'Last Friday of the month');
    });

    test("les messages d'erreur suivent la langue au moment de l'affichage", () {
      const erreur = InvalidCredentialsException();
      expect(erreur.message, 'Email ou mot de passe incorrect.');
      L10n.setLocale(const Locale('en'));
      expect(erreur.message, 'Incorrect email or password.');
    });
  });

  testWidgets("l'accueil de découverte s'affiche entièrement en anglais", (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: '/decouvrir',
      routes: [GoRoute(path: '/decouvrir', builder: (_, _) => const OnboardingPage())],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.textContaining('no notebook'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);
  });
}
