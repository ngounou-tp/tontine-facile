import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Titre de section dans un écran, avec une action discrète à droite
/// (« Voir tout », « Attribuer »).
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.actionLabel, this.onAction, this.actionIcon, super.key});

  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.sectionTitle)),
          if (actionLabel != null && onAction != null)
            actionIcon == null
                ? TextButton(onPressed: onAction, child: Text(actionLabel!))
                : TextButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon, size: 18),
                    label: Text(actionLabel!),
                  ),
        ],
      ),
    );
  }
}
