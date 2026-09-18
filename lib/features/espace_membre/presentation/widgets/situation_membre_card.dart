import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tour.dart';

/// Carte de synthèse de l'espace membre : nom du groupe, noms détenus et
/// prochain tour où l'un d'eux sera bénéficiaire.
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nomTontine,
              style: AppTypography.screenTitle.copyWith(color: AppColors.surface),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              nombreDeNoms > 1 ? '$nombreDeNoms noms détenus' : '$nombreDeNoms nom détenu',
              style: AppTypography.secondary.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.md),
            if (prochainTour == null || prochainNom == null)
              Text(
                'Aucun tour à venir pour vos noms.',
                style: AppTypography.secondary.copyWith(color: AppColors.surface),
              )
            else
              Row(
                children: [
                  const Icon(Icons.event_available_outlined, color: AppColors.accent, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${prochainNom!.libelle} bénéficie le ${_formatDate(prochainTour!.datePrevue)}',
                      style: AppTypography.secondary.copyWith(color: AppColors.surface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
