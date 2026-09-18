import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum AppButtonVariant { primary, secondary, tertiary, destructive, accent }

/// `Size.fromHeight(56)` fixe la HAUTEUR à 56 mais met aussi la largeur à
/// `double.infinity` (c'est ce que fait ce constructeur) : sans un ancêtre
/// qui borne explicitement la largeur (`CrossAxisAlignment.stretch`,
/// `SizedBox`...), un bouton qui reçoit une largeur non bornée (ex. posé nu
/// dans un `Row`) plante avec « BoxConstraints forces an infinite width ».
/// Une largeur minimale finie évite ce piège tout en gardant la même hauteur.
const _tailleMinimale = Size(64, 56);

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.icon, this.variant = AppButtonVariant.primary, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    // FittedBox (plutôt que Flexible/Expanded) : les boutons Material
    // calculent leur taille préférée en interrogeant la largeur intrinsèque
    // de ce contenu, y compris quand ils sont utilisés sans largeur imposée
    // (Row sans Expanded, Center...) — un Flexible dans cette requête
    // intrinsèque lève « BoxConstraints forces an infinite width ». FittedBox
    // n'a pas ce problème : il rétrécit le contenu à l'échelle plutôt que de
    // lui réclamer une part flexible de l'espace disponible.
    final child = busy
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppSpacing.xs)],
                Text(label),
              ],
            ),
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.indigo,
            foregroundColor: AppColors.surface,
            minimumSize: _tailleMinimale,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: busy ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.indigo,
            side: const BorderSide(color: AppColors.indigo),
            minimumSize: _tailleMinimale,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          ),
          child: child,
        ),
      AppButtonVariant.tertiary => TextButton(
          onPressed: busy ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: _tailleMinimale,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          ),
          child: child,
        ),
      AppButtonVariant.destructive => OutlinedButton(
          onPressed: busy ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            minimumSize: _tailleMinimale,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          ),
          child: child,
        ),
      AppButtonVariant.accent => FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.ink,
            minimumSize: _tailleMinimale,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          ),
          child: child,
        ),
    };
    return button;
  }
}