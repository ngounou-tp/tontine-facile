import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../l10n/l10n.dart';
import 'locale_controller.dart';
import 'router.dart';
import 'theme.dart';

class DjanguiBookApp extends ConsumerWidget {
  const DjanguiBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choix = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // `null` : suivre la langue du téléphone (français, anglais, sinon
      // repli sur le français). Les composants système (sélecteur de date,
      // « Coller »…) suivent la même langue.
      locale: choix,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      localeListResolutionCallback: (preferences, _) =>
          choix ?? resolveAppLocale(preferences),
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        L10n.setLocale(locale);
        Intl.defaultLocale = locale.languageCode;
        return child!;
      },
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
