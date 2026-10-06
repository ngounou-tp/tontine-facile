import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/l10n.dart';

/// Formate un nombre de noms (multiple de `0.5`) pour affichage : « 1 nom »,
/// « ½ nom », « 2½ noms »...
String formatterNombreDeNoms(double valeur) {
  final entier = valeur.truncate();
  final demi = valeur - entier >= 0.5 - 1e-9;
  final l10n = L10n.current;
  if (entier == 0 && demi) return l10n.namesCountHalfOnly;
  if (!demi) return l10n.namesCountWhole(entier);
  return l10n.namesCountWithHalf(entier);
}

/// Sélecteur pas-à-pas (par demies) du nombre de noms attribués à un
/// membre — entièrement contrôlé via [value]/[onChanged]. Réutilisé à
/// l'inscription ([MembreForm]) et pour attribuer des noms supplémentaires à
/// un membre déjà enregistré (voir `FicheMembrePage`).
class NombreDeNomsField extends StatelessWidget {
  const NombreDeNomsField({
    required this.value,
    required this.onChanged,
    this.minimum = 0,
    super.key,
  });

  final double value;
  final double minimum;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.namesRemoveHalf,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > minimum ? () => onChanged(value - 0.5) : null,
          ),
          Expanded(
            child: Text(
              formatterNombreDeNoms(value),
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: context.l10n.namesAddHalf,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 0.5),
          ),
        ],
      ),
    );
  }
}
