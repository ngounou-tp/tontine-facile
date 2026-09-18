import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';

/// Demande le motif obligatoire pour lever la pénalité calculée d'une
/// cotisation. Retourne le motif (non vide, sans espaces superflus) si
/// confirmé, `null` si annulé.
Future<String?> demanderMotifExonerationPenalite(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _PenaliteExceptionDialog(),
  );
}

class _PenaliteExceptionDialog extends StatefulWidget {
  const _PenaliteExceptionDialog();

  @override
  State<_PenaliteExceptionDialog> createState() => _PenaliteExceptionDialogState();
}

class _PenaliteExceptionDialogState extends State<_PenaliteExceptionDialog> {
  final _motif = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _confirmer() {
    final valeur = _motif.text.trim();
    if (valeur.isEmpty) {
      setState(() => _erreur = 'Indiquez la raison de cette exception.');
      return;
    }
    Navigator.of(context).pop(valeur);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lever la pénalité'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'La pénalité de retard calculée ne sera pas appliquée à cette '
            'cotisation. Expliquez pourquoi.',
            style: AppTypography.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _motif,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex. panne réseau signalée à l’avance',
              errorText: _erreur,
            ),
            onChanged: (_) {
              if (_erreur != null) setState(() => _erreur = null);
            },
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Annuler',
          variant: AppButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Confirmer',
          variant: AppButtonVariant.accent,
          onPressed: _confirmer,
        ),
      ],
    );
  }
}
