import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum StatusBadgeType { paid, late, partial, exception, toCollect }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.type});

  final StatusBadgeType type;

  @override
  Widget build(BuildContext context) {
    final style = _styles[type]!;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: style.background, border: Border.all(color: style.border), borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
      child: Text(style.label, style: AppTypography.micro.copyWith(color: style.foreground)),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle(this.label, this.background, this.foreground, this.border);

  final String label;
  final Color background;
  final Color foreground;
  final Color border;
}

const _styles = <StatusBadgeType, _BadgeStyle>{
  StatusBadgeType.paid: _BadgeStyle('Payé', AppColors.success, AppColors.surface, AppColors.success),
  StatusBadgeType.late: _BadgeStyle('En retard', AppColors.danger, AppColors.surface, AppColors.danger),
  StatusBadgeType.partial: _BadgeStyle('Partiel', AppColors.warning, AppColors.ink, AppColors.warning),
  StatusBadgeType.exception: _BadgeStyle('Exception', AppColors.warning, AppColors.ink, AppColors.warning),
  StatusBadgeType.toCollect: _BadgeStyle('À encaisser', AppColors.canvas, AppColors.slate, AppColors.line),
};