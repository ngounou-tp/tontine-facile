import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Barre de progression de la collecte du tour en cours : montant collecté
/// (cotisations validées) face au montant total attendu.
class ContributionProgress extends StatelessWidget {
  const ContributionProgress({required this.collecte, required this.attendu, super.key});

  final int collecte;
  final int attendu;

  @override
  Widget build(BuildContext context) {
    final progression = attendu <= 0 ? 0.0 : (collecte / attendu).clamp(0.0, 1.0);
    final complet = attendu > 0 && collecte >= attendu;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Collecte du tour', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${(progression * 100).round()} %',
                  style: AppTypography.body.copyWith(
                    color: complet ? AppColors.success : AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: LinearProgressIndicator(
                value: progression,
                minHeight: 8,
                backgroundColor: AppColors.canvas,
                color: complet ? AppColors.success : AppColors.indigo,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('$collecte / $attendu FCFA', style: AppTypography.secondary),
          ],
        ),
      ),
    );
  }
}
