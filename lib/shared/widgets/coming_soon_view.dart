import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Contenu (sans Scaffold) d'un écran pas encore construit : icône, titre et
/// message rassurant plutôt qu'une page blanche. Se place dans le `body` de
/// n'importe quel Scaffold ou [AppScaffold] — voir [RoutePlaceholderPage]
/// pour l'emballage par défaut.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    required this.title,
    this.message = 'Cette fonctionnalité arrive bientôt.',
    this.icon = Icons.construction_outlined,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Icon(icon, color: AppColors.indigo, size: 40),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center, style: AppTypography.secondary),
          ],
        ),
      ),
    );
  }
}
