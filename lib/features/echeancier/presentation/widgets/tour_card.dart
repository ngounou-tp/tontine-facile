import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../domain/entities/changement.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/enums/statut_tour.dart';
import '../../../../l10n/l10n.dart';

String libelleStatutTour(StatutTour statut, AppLocalizations l10n) => switch (statut) {
      StatutTour.aVenir => l10n.turnStatusUpcoming,
      StatutTour.enCours => l10n.turnStatusInProgress,
      StatutTour.remis => l10n.turnStatusPaid,
      StatutTour.reporte => l10n.turnStatusPostponed,
    };

AppTone tonStatutTour(StatutTour statut) => switch (statut) {
      StatutTour.aVenir => AppTone.neutral,
      StatutTour.enCours => AppTone.info,
      StatutTour.remis => AppTone.success,
      StatutTour.reporte => AppTone.warning,
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
    if (courant == null) return L10n.current.unknownName;
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

  List<Changement> get _historiqueDuTour =>
      changements.where((c) => c.tourId == tour.id).toList(growable: false);

  void _ouvrirHistorique(BuildContext context) {
    final historique = _historiqueDuTour;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.turnHistoryTitle, style: AppTypography.sectionTitle),
              Text(_beneficiaires, style: AppTypography.secondary),
              const SizedBox(height: AppSpacing.lg),
              for (final changement in historique)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.swap_vert, size: 18, color: AppColors.indigo),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.turnPositionChange(changement.anciennePosition, changement.nouvellePosition),
                              style: AppTypography.bodyStrong,
                            ),
                            Text(changement.motif, style: AppTypography.secondary),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(formatDate(changement.createdAt), style: AppTypography.micro),
                          ],
                        ),
                      ),
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
    final historique = _historiqueDuTour;
    final remis = tour.statut == StatutTour.remis;
    return AppCard(
      onTap: onTap,
      borderColor: enEvidence ? AppColors.indigo : null,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Numéro du tour : plein pour le tour en cours, coché une fois
              // remis — la colonne se lit comme une frise.
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enEvidence
                      ? AppColors.indigo
                      : remis
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.canvas,
                  shape: BoxShape.circle,
                ),
                child: remis
                    ? const Icon(Icons.check, size: 20, color: AppColors.success)
                    : Text(
                        '${tour.position}',
                        style: AppTypography.bodyStrong.copyWith(
                          color: enEvidence ? AppColors.surface : AppColors.ink,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _beneficiaires,
                      style: AppTypography.bodyStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      remis
                          ? context.l10n.turnPaidOn(formatDate(tour.datePrevue))
                          : context.l10n.turnPlannedOn(formatDate(tour.datePrevue)),
                      style: AppTypography.secondary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppPill(label: libelleStatutTour(tour.statut, context.l10n), tone: tonStatutTour(tour.statut)),
                  if (remis && tour.montantRemis != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(formatAmount(tour.montantRemis!), style: AppTypography.amountInline),
                  ],
                ],
              ),
            ],
          ),
          if (historique.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _ouvrirHistorique(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTypography.micro,
                ),
                icon: const Icon(Icons.history, size: 16),
                label: Text(
                  context.l10n.turnChangesSeeHistory(historique.length),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
