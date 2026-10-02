import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Demande confirmation avant une action lourde de conséquences. Le bouton
/// de confirmation reprend le verbe de l'action (« Désactiver », pas
/// « OK ») : on sait ce qu'on accepte sans relire la question.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  required String libelleConfirmation,
  bool destructif = false,
}) async {
  final resultat = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructif ? AppColors.danger : AppColors.indigo,
            foregroundColor: AppColors.surface,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          ),
          child: Text(libelleConfirmation),
        ),
      ],
    ),
  );
  return resultat ?? false;
}
