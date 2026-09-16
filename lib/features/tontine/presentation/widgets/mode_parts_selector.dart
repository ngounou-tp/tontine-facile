import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/enums/mode_parts.dart';

/// Sélecteur du mode de répartition des parts fractionnaires d'un nom (voir
/// `ModeParts`). Entièrement contrôlé : [value]/[onChanged].
class ModePartsSelector extends StatelessWidget {
  const ModePartsSelector({required this.value, required this.onChanged, super.key});

  final ModeParts value;
  final ValueChanged<ModeParts> onChanged;

  static String _description(ModeParts mode) => switch (mode) {
        ModeParts.montantFixe =>
          'Chaque détenteur de part verse le même montant fixe, quelle que soit sa fraction.',
        ModeParts.proportionnel =>
          'Chaque détenteur verse un montant proportionnel à sa fraction du nom.',
        ModeParts.partEgale =>
          'Le montant du nom est réparti à parts égales entre ses détenteurs.',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final mode in ModeParts.values) ...[
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            onTap: () => onChanged(mode),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                border: Border.all(
                  color: mode == value ? AppColors.indigo : AppColors.line,
                  width: mode == value ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    mode == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: mode == value ? AppColors.indigo : AppColors.slate,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mode.libelle, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_description(mode), style: AppTypography.secondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (mode != ModeParts.values.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
