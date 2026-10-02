import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/declaration.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/member_avatar.dart';

/// Ligne résumant une déclaration de paiement : membre, nom, montant, date
/// déclarée et statut (en attente, validée, contestée).
class DeclarationCard extends StatelessWidget {
  const DeclarationCard({
    required this.declaration,
    required this.membre,
    required this.nom,
    required this.onTap,
    super.key,
  });

  final Declaration declaration;
  final Membre? membre;
  final Nom? nom;
  final VoidCallback onTap;

  ({String label, AppTone ton}) get _statut => switch (declaration.statut.name) {
        'validee' => (label: 'Validée', ton: AppTone.success),
        'enAttente' => (label: 'En attente', ton: AppTone.warning),
        _ => (label: 'Contestée', ton: AppTone.danger),
      };

  @override
  Widget build(BuildContext context) {
    final statut = _statut;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          MemberAvatar(nomComplet: membre?.nomComplet ?? '?'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membre?.nomComplet ?? 'Membre inconnu',
                  style: AppTypography.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${nom?.libelle ?? 'Nom inconnu'} · ${formatDate(declaration.datePaiement)}',
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
              Text(formatAmount(declaration.montantDeclare), style: AppTypography.amountInline),
              const SizedBox(height: AppSpacing.xxs),
              AppPill(label: statut.label, tone: statut.ton),
            ],
          ),
        ],
      ),
    );
  }
}
