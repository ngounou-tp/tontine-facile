import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/enums/statut_tour.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../l10n/l10n.dart';

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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$remis', style: AppTypography.amount.copyWith(fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(
                    context.l10n.turnsPaidOf(total),
                    style: AppTypography.secondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(context.l10n.percentValue((progression * 100).round()), style: AppTypography.micro),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppProgressBar(value: progression, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
