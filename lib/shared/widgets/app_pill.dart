import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Sens d'une pastille : la couleur porte toujours une signification, jamais
/// une décoration (voir `flutter-design-bridge`).
enum AppTone { neutral, info, success, warning, danger }

/// Pastille de statut unique de l'app (« Payé », « En retard », « En
/// attente »…). Fond teinté + texte foncé de la même famille : lisible en
/// plein soleil et calme à l'œil, là où un fond saturé crierait dans une
/// liste de vingt lignes.
class AppPill extends StatelessWidget {
  const AppPill({required this.label, this.tone = AppTone.neutral, super.key});

  final String label;
  final AppTone tone;

  static Color foregroundOf(AppTone tone) => switch (tone) {
        AppTone.neutral => AppColors.slate,
        AppTone.info => AppColors.indigo,
        AppTone.success => AppColors.success,
        AppTone.warning => AppColors.warningInk,
        AppTone.danger => AppColors.danger,
      };

  static Color backgroundOf(AppTone tone) => switch (tone) {
        AppTone.neutral => AppColors.canvas,
        AppTone.info => AppColors.indigo.withValues(alpha: 0.10),
        AppTone.success => AppColors.success.withValues(alpha: 0.12),
        AppTone.warning => AppColors.warning.withValues(alpha: 0.16),
        AppTone.danger => AppColors.danger.withValues(alpha: 0.10),
      };

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundOf(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundOf(tone),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          // Flexible : dans une colonne étroite, un libellé long (« En
          // attente d'inscription ») se tronque au lieu de déborder.
          Flexible(
            child: Text(
              label,
              style: AppTypography.micro.copyWith(color: foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
