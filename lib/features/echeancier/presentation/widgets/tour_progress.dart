import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/enums/statut_tour.dart';

/// Résumé de progression de l'échéancier complet : proportion de tours
/// remis sur le total.
class TourProgress extends StatelessWidget {
  const TourProgress({required this.tours, super.key});

  final List<Tour> tours;

  @override
  Widget build(BuildContext context) {
    final total = tours.length;
    final remis = tours.where((t) => t.statut == StatutTour.remis).length;
    final progression = total == 0 ? 0.0 : remis / total;

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
                  child: Text('Échéancier', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('$remis / $total tours remis', style: AppTypography.secondary),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: LinearProgressIndicator(
                value: progression,
                minHeight: 8,
                backgroundColor: AppColors.canvas,
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
