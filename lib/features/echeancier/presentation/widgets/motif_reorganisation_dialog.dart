import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../l10n/l10n.dart';

/// Demande le motif obligatoire d'un changement d'ordre dans l'échéancier
/// ([ReorganisateurTours]). Retourne le motif (non vide) si confirmé,
/// `null` si annulé.
Future<String?> demanderMotifReorganisation(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _MotifReorganisationDialog(),
  );
}

class _MotifReorganisationDialog extends StatefulWidget {
  const _MotifReorganisationDialog();

  @override
  State<_MotifReorganisationDialog> createState() => _MotifReorganisationDialogState();
}

class _MotifReorganisationDialogState extends State<_MotifReorganisationDialog> {
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
      setState(() => _erreur = context.l10n.reorderReasonRequired);
      return;
    }
    Navigator.of(context).pop(valeur);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.reorderTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reorderExplanation,
            style: AppTypography.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _motif,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.l10n.reorderHint,
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
