import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Bascule vers l'onglet [index] (Accueil, Membres, Échéancier, Réglages) :
  /// callback prêt à l'emploi pour [onSelected] sur les écrans principaux.
  static void go(BuildContext context, int index) {
    final destination = switch (index) {
      1 => AppRouter.membresPath,
      2 => AppRouter.echeancierPath,
      3 => AppRouter.reglagesPath,
      _ => AppRouter.accueilPath,
    };
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 64,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      indicatorColor: AppColors.canvas,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Membres'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Échéancier'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Réglages'),
      ],
    );
  }
}