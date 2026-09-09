import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum AppButtonVariant { primary, secondary, tertiary, destructive }

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.icon, this.variant = AppButtonVariant.primary, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppSpacing.xs)], Text(label)]);
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: busy ? null : onPressed, child: child),
      AppButtonVariant.secondary => OutlinedButton(onPressed: busy ? null : onPressed, child: child),
      AppButtonVariant.tertiary => TextButton(onPressed: busy ? null : onPressed, child: child),
      AppButtonVariant.destructive => OutlinedButton(onPressed: busy ? null : onPressed, style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)), child: child),
    };
    return SizedBox(height: 48, child: button);
  }
}