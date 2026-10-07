import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Bascule vers l'onglet [index] (Accueil, Membres, Échéancier,
  /// Déclarations, Réglages) : callback prêt à l'emploi pour [onSelected]
  /// sur les écrans principaux. Identique pour l'administratrice et les
  /// membres, qui consultent les quatre premiers onglets en lecture seule.
  static void go(BuildContext context, int index) {
    final destination = switch (index) {
      1 => AppRouter.membresPath,
      2 => AppRouter.echeancierPath,
      3 => AppRouter.declarationsPath,
      4 => AppRouter.reglagesPath,
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
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.indigo), label: context.l10n.navHome),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups, color: AppColors.indigo), label: context.l10n.navMembers),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: AppColors.indigo), label: context.l10n.navSchedule),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: AppColors.indigo), label: context.l10n.navDeclarations),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.indigo), label: context.l10n.navSettings),
      ],
    );
  }
}