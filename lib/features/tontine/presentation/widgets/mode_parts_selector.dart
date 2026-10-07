import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/enums/mode_parts.dart';
import '../../../../l10n/domain_labels.dart';
import '../../../../l10n/l10n.dart';

/// Sélecteur du mode de répartition des parts fractionnaires d'un nom (voir
/// `ModeParts`). Entièrement contrôlé : [value]/[onChanged].
class ModePartsSelector extends StatelessWidget {
  const ModePartsSelector({required this.value, required this.onChanged, super.key});

  final ModeParts value;
  final ValueChanged<ModeParts> onChanged;

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
                        Text(mode.label(context.l10n), style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(mode.description(context.l10n), style: AppTypography.secondary),
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
