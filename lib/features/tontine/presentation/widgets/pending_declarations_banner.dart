import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../l10n/l10n.dart';

/// Bannière du tableau de bord signalant des déclarations de paiement en
/// attente de traitement — masquée si [nombre] vaut 0. Apparaît et
/// disparaît en douceur (hauteur + fondu) au lieu de faire sauter la page.
class PendingDeclarationsBanner extends StatelessWidget {
  const PendingDeclarationsBanner({required this.nombre, this.onTap, super.key});

  final int nombre;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        child: nombre == 0
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: const ValueKey('banniere'),
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: AppCard(
                  onTap: onTap,
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderColor: AppColors.warning.withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                        child: Text(
                          '$nombre',
                          style: AppTypography.bodyStrong.copyWith(color: AppColors.surface, height: 1),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.bannerPendingDeclarations(nombre),
                              style: AppTypography.bodyStrong,
                            ),
                            Text(
                              context.l10n.bannerCheckProofs,
                              style: AppTypography.secondary.copyWith(color: AppColors.warningInk),
                            ),
                          ],
                        ),
                      ),
                      if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.warningInk),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
