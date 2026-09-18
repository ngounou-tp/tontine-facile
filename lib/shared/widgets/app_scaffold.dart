import 'package:flutter/material.dart';

import 'app_navigation.dart';

/// Scaffold partagé par les cinq sections principales de l'application
/// (Accueil, Membres, Échéancier, Déclarations, Réglages) : assure que la
/// barre de navigation inférieure est toujours présente et cohérente, quel
/// que soit l'écran — y compris pour un membre, qui consulte ces mêmes
/// sections en lecture seule (voir `isAdminProvider`). Les écrans
/// secondaires (fiche membre, formulaires…), atteints depuis une section
/// plutôt qu'en étant eux-mêmes une section, utilisent un [Scaffold]
/// classique avec une flèche de retour à la place.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.selectedNavIndex,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    super.key,
  });

  /// Onglet actif : 0 Accueil, 1 Membres, 2 Échéancier, 3 Déclarations,
  /// 4 Réglages.
  final int selectedNavIndex;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: AppNavigation(
        selectedIndex: selectedNavIndex,
        onSelected: (index) => AppNavigation.go(context, index),
      ),
    );
  }
}
