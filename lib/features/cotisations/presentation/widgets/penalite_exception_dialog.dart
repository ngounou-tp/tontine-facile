import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../l10n/l10n.dart';

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
      setState(() => _erreur = context.l10n.waiverReasonRequired);
      return;
    }
    Navigator.of(context).pop(valeur);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.contribWaivePenalty),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.waiverExplanation,
            style: AppTypography.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _motif,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.l10n.waiverHint,
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
          label: context.l10n.commonCancel,
          variant: AppButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: context.l10n.commonConfirm,
          variant: AppButtonVariant.accent,
          onPressed: _confirmer,
        ),
      ],
    );
  }
}
