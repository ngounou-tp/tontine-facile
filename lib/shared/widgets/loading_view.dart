import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// État de chargement générique, centré : à utiliser à la place d'un
/// `CircularProgressIndicator` nu pour un rendu cohérent dans toute
/// l'application (couleur de marque, message optionnel).
class LoadingView extends StatelessWidget {
  const LoadingView({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.indigo),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: AppTypography.secondary),
          ],
        ],
      ),
    );
  }
}
