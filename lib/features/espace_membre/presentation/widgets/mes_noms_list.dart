import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Aucun tour en cours pour vos noms.', style: AppTypography.secondary),
        ),
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
    final (label, couleur) = switch (true) {
      _ when situation.solde => ('Payé', AppColors.success),
      _ when situation.declarationEnAttente => ('Déclaration en attente', AppColors.warning),
      _ when situation.declarationContestee => ('Déclaration contestée', AppColors.danger),
      _ when situation.montantVerse > 0 => ('Partiel', AppColors.warning),
      _ => ('Impayé', AppColors.slate),
    };

    return Card(
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
                    formatFraction(situation.fraction),
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.indigo),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        situation.nom.libelle,
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatFraction(situation.fraction)} · ${situation.montantVerse}/${situation.montantDu} FCFA',
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
                  child: Text(label, style: AppTypography.micro.copyWith(color: couleur)),
                ),
              ],
            ),
            if (situation.declarationContestee && situation.motifContestation != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Motif : ${situation.motifContestation}',
                style: AppTypography.secondary.copyWith(color: AppColors.danger),
              ),
            ],
            if (situation.peutDeclarer) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: onDeclarer,
                child: Text(situation.declarationContestee ? 'Faire une nouvelle déclaration' : "J'ai payé"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
