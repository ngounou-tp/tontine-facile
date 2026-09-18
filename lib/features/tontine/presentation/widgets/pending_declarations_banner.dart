import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Bannière du tableau de bord signalant des déclarations de paiement en
/// attente de traitement — masquée si [nombre] vaut 0.
class PendingDeclarationsBanner extends StatelessWidget {
  const PendingDeclarationsBanner({required this.nombre, this.onTap, super.key});

  final int nombre;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (nombre == 0) return const SizedBox.shrink();
    return Card(
      color: AppColors.warning.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  nombre == 1
                      ? '1 déclaration de paiement à traiter'
                      : '$nombre déclarations de paiement à traiter',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}
