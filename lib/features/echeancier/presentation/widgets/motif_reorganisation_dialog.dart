import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';

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
      setState(() => _erreur = 'Indiquez la raison de ce changement.');
      return;
    }
    Navigator.of(context).pop(valeur);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Déplacer ce tour"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Les dates des tours suivants seront recalculées. Expliquez pourquoi "
            "l'ordre change.",
            style: AppTypography.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _motif,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex. absence exceptionnelle, demande du membre…',
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
