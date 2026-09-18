import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Carte de résumé du tableau de bord : montant total distribué à chaque
/// tour (montant par nom × nombre de noms).
class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({required this.montantParTour, super.key});

  final int montantParTour;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribué par tour',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$montantParTour FCFA',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.surface),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.savings_outlined, color: AppColors.ink, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
