import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../l10n/l10n.dart';

/// Carte de synthèse de l'espace membre : nom du groupe, noms détenus et
/// prochain tour où l'un d'eux sera bénéficiaire — le moment que chaque
/// membre attend, mis en avant comme un compte à rebours.
class SituationMembreCard extends StatelessWidget {
  const SituationMembreCard({
    required this.nomTontine,
    required this.nombreDeNoms,
    required this.prochainTour,
    required this.prochainNom,
    super.key,
  });

  final String nomTontine;
  final int nombreDeNoms;
  final Tour? prochainTour;
  final Nom? prochainNom;

  @override
  Widget build(BuildContext context) {
    final tour = prochainTour;
    final nom = prochainNom;
    return Card(
      color: AppColors.ink,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nomTontine.toUpperCase(),
              style: AppTypography.overline.copyWith(color: AppColors.accent),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (tour == null || nom == null) ...[
              Text(
                context.l10n.situationNoUpcomingTurn,
                style: AppTypography.sectionTitle.copyWith(color: AppColors.surface),
              ),
            ] else ...[
              Text(
                context.l10n.situationYourNextTurn,
                style: AppTypography.secondary.copyWith(color: AppColors.onInkMuted),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                formatDate(tour.datePrevue),
                style: AppTypography.amountXl.copyWith(color: AppColors.surface, fontSize: 30),
              ),
              Text(
                context.l10n.situationTurnLine(nom.libelle, tour.position, formatEcheanceRelative(tour.datePrevue)),
                style: AppTypography.secondary.copyWith(color: AppColors.onInkMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  context.l10n.profileNamesHeldCount(nombreDeNoms),
                  style: AppTypography.secondary.copyWith(color: AppColors.surface),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
