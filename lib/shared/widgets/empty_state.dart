import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_button.dart';
import 'app_card.dart';

/// État vide : dit ce qui manque ET quoi faire ensuite. Un écran vide sans
/// action laisse l'utilisatrice bloquée.
///
/// [compact] : version carte, posée dans une liste au milieu d'autres
/// sections. Sinon : version centrée qui occupe tout l'écran.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final action = actionLabel != null && onAction != null;
    if (compact) {
      return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              ),
              child: Icon(icon, color: AppColors.indigo, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: AppTypography.bodyStrong),
                    const SizedBox(height: 2),
                  ],
                  Text(message, style: AppTypography.secondary),
                  if (action) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                ),
                child: Icon(icon, color: AppColors.indigo, size: 32),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (title != null) ...[
                Text(title!, textAlign: TextAlign.center, style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(message, textAlign: TextAlign.center, style: AppTypography.secondary),
              if (action) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: actionLabel!, variant: AppButtonVariant.secondary, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
