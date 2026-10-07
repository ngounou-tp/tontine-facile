import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_button.dart';
import '../../l10n/l10n.dart';

/// État d'erreur générique, centré : à utiliser à chaque fois qu'un flux
/// Firestore échoue (`AsyncValue.error`), plutôt que de retomber
/// silencieusement sur une liste vide — l'administratrice doit savoir que
/// quelque chose a échoué, pas croire qu'il n'y a simplement rien à afficher.
class ErrorView extends StatelessWidget {
  const ErrorView({this.message, this.onRetry, super.key});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? context.l10n.errorGeneric,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: context.l10n.commonRetry, variant: AppButtonVariant.secondary, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
