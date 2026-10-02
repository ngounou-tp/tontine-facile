import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class TontineFacileApp extends ConsumerWidget {
  const TontineFacileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TontineFacile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Composants système en français (sélecteur de date, « Coller »,
      // « Annuler »…) : l'app ne bascule plus en anglais au détour d'un
      // calendrier.
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
