import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/changement.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/enums/statut_tour.dart';

String libelleStatutTour(StatutTour statut) => switch (statut) {
      StatutTour.aVenir => 'À venir',
      StatutTour.enCours => 'En cours',
      StatutTour.remis => 'Remis',
      StatutTour.reporte => 'Reporté',
    };

Color couleurStatutTour(StatutTour statut) => switch (statut) {
      StatutTour.aVenir => AppColors.slate,
      StatutTour.enCours => AppColors.indigo,
      StatutTour.remis => AppColors.success,
      StatutTour.reporte => AppColors.warning,
    };

/// Ligne de l'échéancier (lecture seule) : position, bénéficiaire, date
/// prévue, statut, et montant remis une fois le tour complété. Le tour en
/// cours est mis en évidence via [enEvidence].
class TourCard extends StatelessWidget {
  const TourCard({
    required this.tour,
    required this.nom,
    required this.membres,
    this.changements = const [],
    this.enEvidence = false,
    this.onTap,
    super.key,
  });

  final Tour tour;
  final Nom? nom;
  final List<Membre> membres;

  /// Historique complet de la tontine — filtré en interne sur ce tour
  /// (voir [Changement.tourId]) : le caller n'a pas besoin de pré-filtrer.
  final List<Changement> changements;
  final bool enEvidence;
  final VoidCallback? onTap;

  String get _beneficiaires {
    final courant = nom;
    if (courant == null) return 'Nom inconnu';
    final noms = <String>[];
    for (final part in courant.parts) {
      for (final membre in membres) {
        if (membre.id == part.membreId) {
          noms.add(membre.nomComplet);
          break;
        }
      }
    }
    return noms.isEmpty ? courant.libelle : noms.join(' & ');
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  List<Changement> get _historiqueDuTour =>
      changements.where((c) => c.tourId == tour.id).toList(growable: false);

  void _ouvrirHistorique(BuildContext context) {
    final historique = _historiqueDuTour;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Historique — $_beneficiaires', style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.md),
              for (final changement in historique)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Position ${changement.anciennePosition} → ${changement.nouvellePosition}',
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(changement.motif, style: AppTypography.secondary),
                      const SizedBox(height: 2),
                      Text(_formatDate(changement.createdAt), style: AppTypography.micro),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final couleur = couleurStatutTour(tour.statut);
    final historique = _historiqueDuTour;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: enEvidence
          ? RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.indigo, width: 2),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.canvas,
                    child: Text(
                      '${tour.position}',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _beneficiaires,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tour.statut == StatutTour.remis
                              ? 'Remis le ${_formatDate(tour.datePrevue)}'
                              : 'Prévu le ${_formatDate(tour.datePrevue)}',
                          style: AppTypography.secondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Text(
                      libelleStatutTour(tour.statut),
                      style: AppTypography.micro.copyWith(color: couleur),
                    ),
                  ),
                ],
              ),
              if (tour.statut == StatutTour.remis && tour.montantRemis != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${tour.montantRemis} FCFA', style: AppTypography.secondary),
                ),
              ],
              if (historique.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => _ouvrirHistorique(context),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 14, color: AppColors.slate),
                      const SizedBox(width: 4),
                      Text(
                        historique.length > 1
                            ? '${historique.length} changements — voir l\'historique'
                            : 'Repositionné — voir l\'historique',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.indigo,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
