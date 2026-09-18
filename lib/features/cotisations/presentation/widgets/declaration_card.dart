import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/declaration.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';

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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  ({String label, Color color}) get _statut => switch (declaration.statut.name) {
        'validee' => (label: 'Validée', color: AppColors.success),
        'enAttente' => (label: 'En attente', color: AppColors.warning),
        _ => (label: 'Contestée', color: AppColors.danger),
      };

  @override
  Widget build(BuildContext context) {
    final statut = _statut;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.canvas,
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.indigo, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membre?.nomComplet ?? 'Membre inconnu',
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${nom?.libelle ?? 'Nom inconnu'} · Déclaré le ${_formatDate(declaration.datePaiement)}',
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
                  Text(
                    '${declaration.montantDeclare} FCFA',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: statut.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Text(
                      statut.label,
                      style: AppTypography.micro.copyWith(color: statut.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}
