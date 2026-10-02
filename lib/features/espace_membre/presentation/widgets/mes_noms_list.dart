import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../membres/presentation/widgets/parts_editor.dart' show formatFraction;
import '../../application/espace_membre_providers.dart';

/// Liste des noms détenus par le membre connecté, avec leur situation pour
/// le tour en cours (« Payé », « Partiel », « Impayé ») et l'action
/// « J'ai payé » quand une déclaration est possible pour ce nom.
class MesNomsList extends StatelessWidget {
  const MesNomsList({
    required this.situations,
    required this.onDeclarer,
    super.key,
  });

  final List<SituationNomTourActuel> situations;
  final void Function(SituationNomTourActuel situation) onDeclarer;

  @override
  Widget build(BuildContext context) {
    if (situations.isEmpty) {
      return const EmptyState(
        compact: true,
        icon: Icons.event_available_outlined,
        message: 'Aucun tour en cours pour vos noms.',
      );
    }
    return Column(
      children: [
        for (final situation in situations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _NomSituationCard(situation: situation, onDeclarer: () => onDeclarer(situation)),
          ),
      ],
    );
  }
}

class _NomSituationCard extends StatelessWidget {
  const _NomSituationCard({required this.situation, required this.onDeclarer});

  final SituationNomTourActuel situation;
  final VoidCallback onDeclarer;

  @override
  Widget build(BuildContext context) {
    final (label, ton) = switch (true) {
      _ when situation.solde => ('Payé', AppTone.success),
      _ when situation.declarationEnAttente => ('Déclaration en attente', AppTone.warning),
      _ when situation.declarationContestee => ('Déclaration contestée', AppTone.danger),
      _ when situation.montantVerse > 0 => ('Partiel', AppTone.warning),
      _ => ('Impayé', AppTone.neutral),
    };
    final progression = situation.montantDu <= 0 ? 0.0 : situation.montantVerse / situation.montantDu;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(situation.nom.libelle, style: AppTypography.bodyStrong),
                    Text(
                      'Part : ${formatFraction(situation.fraction)}',
                      style: AppTypography.secondary,
                    ),
                  ],
                ),
              ),
              AppPill(label: label, tone: ton),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatAmount(situation.montantVerse), style: AppTypography.amount),
              Expanded(
                child: Text(
                  ' / ${formatAmount(situation.montantDu)}',
                  style: AppTypography.secondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppProgressBar(
            value: progression,
            height: 6,
            color: situation.solde ? AppColors.success : AppColors.indigo,
          ),
          if (situation.declarationContestee && situation.motifContestation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Motif du refus : ${situation.motifContestation}',
              style: AppTypography.secondary.copyWith(color: AppColors.danger),
            ),
          ],
          if (situation.peutDeclarer) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: situation.declarationContestee ? 'Faire une nouvelle déclaration' : "J'ai payé",
              icon: Icons.upload_outlined,
              variant: AppButtonVariant.accent,
              onPressed: onDeclarer,
            ),
          ],
        ],
      ),
    );
  }
}
