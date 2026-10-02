import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/empty_state.dart';

/// Carte principale du tableau de bord : répond d'un coup d'œil à « qui
/// reçoit la cagnotte de ce tour, quand, et où en est la collecte ? ». Le
/// montant collecté est le plus gros élément de l'écran.
///
/// États vides : échéancier non généré, ou tous les tours remis.
class CurrentTourCard extends StatelessWidget {
  const CurrentTourCard({
    required this.tour,
    required this.noms,
    required this.membres,
    required this.tourGenere,
    required this.totalCollecte,
    required this.totalAttendu,
    this.onCollecter,
    this.onPreparer,
    super.key,
  });

  final Tour? tour;
  final List<Nom> noms;
  final List<Membre> membres;
  final bool tourGenere;
  final int totalCollecte;
  final int totalAttendu;
  final VoidCallback? onCollecter;

  /// Action de l'état vide « échéancier non généré » (aller aux Membres).
  final VoidCallback? onPreparer;

  Nom? _nom(String nomId) {
    for (final nom in noms) {
      if (nom.id == nomId) return nom;
    }
    return null;
  }

  String _beneficiaires(Nom? nom) {
    if (nom == null) return 'Nom inconnu';
    final noms = <String>[];
    for (final part in nom.parts) {
      for (final membre in membres) {
        if (membre.id == part.membreId) {
          noms.add(membre.nomComplet);
          break;
        }
      }
    }
    return noms.isEmpty ? nom.libelle : noms.join(' & ');
  }

  @override
  Widget build(BuildContext context) {
    if (!tourGenere) {
      return EmptyState(
        compact: true,
        icon: Icons.event_note_outlined,
        title: 'Échéancier à préparer',
        message: "L'échéancier n'a pas encore été généré. Attribuez les noms puis générez-le depuis Membres.",
        actionLabel: onPreparer == null ? null : 'Aller aux membres',
        onAction: onPreparer,
      );
    }
    final tourActuel = tour;
    if (tourActuel == null) {
      return const EmptyState(
        compact: true,
        icon: Icons.celebration_outlined,
        title: 'Tontine terminée',
        message: 'Tous les tours ont été remis. Bravo !',
      );
    }

    final progression = totalAttendu <= 0 ? 0.0 : (totalCollecte / totalAttendu).clamp(0.0, 1.0);
    final complet = totalAttendu > 0 && totalCollecte >= totalAttendu;
    final echeance = tourActuel.datePrevue;

    return Card(
      color: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TOUR ${tourActuel.position} · EN COURS',
                    style: AppTypography.overline.copyWith(color: AppColors.accent),
                  ),
                ),
                _PastillePourcentage(progression: progression, complet: complet),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _beneficiaires(_nom(tourActuel.nomId)),
              style: AppTypography.sectionTitle.copyWith(color: AppColors.surface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Reçoit ${formatAmount(totalAttendu)} · ${formatDateCourte(echeance)} '
              '(${formatEcheanceRelative(echeance)})',
              style: AppTypography.secondary.copyWith(color: AppColors.onInkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              formatAmount(totalCollecte),
              style: AppTypography.amountXl.copyWith(color: AppColors.surface),
            ),
            Text(
              'collectés sur ${formatAmount(totalAttendu)}',
              style: AppTypography.secondary.copyWith(color: AppColors.onInkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppProgressBar(
              value: progression,
              color: complet ? AppColors.success : AppColors.accent,
              trackColor: AppColors.surface.withValues(alpha: 0.14),
            ),
            if (onCollecter != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: complet ? 'Voir la collecte' : 'Collecter les cotisations',
                icon: complet ? Icons.check_circle_outline : Icons.payments_outlined,
                variant: AppButtonVariant.accent,
                onPressed: onCollecter,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PastillePourcentage extends StatelessWidget {
  const _PastillePourcentage({required this.progression, required this.complet});

  final double progression;
  final bool complet;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: complet ? AppColors.success : AppColors.surface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${(progression * 100).round()} %',
        style: AppTypography.micro.copyWith(
          color: AppColors.surface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
