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

class AppButton extends StatefulWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.icon, this.variant = AppButtonVariant.primary, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool busy;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  // Suit l'état « pressé » du bouton Material pour le tasser sous le doigt
  // (retour tactile immédiat, avant même que l'action ne réponde).
  final _etats = WidgetStatesController();
  var _enfonce = false;

  @override
  void initState() {
    super.initState();
    _etats.addListener(_surChangementEtat);
  }

  void _surChangementEtat() {
    final enfonce = _etats.value.contains(WidgetState.pressed);
    if (enfonce != _enfonce) setState(() => _enfonce = enfonce);
  }

  @override
  void dispose() {
    _etats
      ..removeListener(_surChangementEtat)
      ..dispose();
    super.dispose();
  }

  Color get _couleurContenu => switch (widget.variant) {
        AppButtonVariant.primary => AppColors.surface,
        AppButtonVariant.accent => AppColors.ink,
        AppButtonVariant.destructive => AppColors.danger,
        _ => AppColors.indigo,
      };

  @override
  Widget build(BuildContext context) {
    final busy = widget.busy;
    final onPressed = busy ? null : widget.onPressed;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius));

    // FittedBox (plutôt que Flexible/Expanded) : les boutons Material
    // calculent leur taille préférée en interrogeant la largeur intrinsèque
    // de ce contenu, y compris quand ils sont utilisés sans largeur imposée
    // (Row sans Expanded, Center...) — un Flexible dans cette requête
    // intrinsèque lève « BoxConstraints forces an infinite width ». FittedBox
    // n'a pas ce problème : il rétrécit le contenu à l'échelle plutôt que de
    // lui réclamer une part flexible de l'espace disponible.
    //
    // Le libellé reste dans l'arbre (invisible) pendant le chargement : le
    // bouton garde sa largeur au lieu de rétrécir autour du spinner.
    final child = Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: busy ? 0 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 20), const SizedBox(width: AppSpacing.xs)],
                Text(widget.label),
              ],
            ),
          ),
        ),
        if (busy)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _couleurContenu),
          ),
      ],
    );

    final button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          statesController: _etats,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.indigo,
            foregroundColor: AppColors.surface,
            minimumSize: _tailleMinimale,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          statesController: _etats,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.indigo,
            side: const BorderSide(color: AppColors.indigo),
            minimumSize: _tailleMinimale,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.tertiary => TextButton(
          onPressed: onPressed,
          statesController: _etats,
          style: TextButton.styleFrom(
            minimumSize: _tailleMinimale,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.destructive => OutlinedButton(
          onPressed: onPressed,
          statesController: _etats,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            minimumSize: _tailleMinimale,
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.accent => FilledButton(
          onPressed: onPressed,
          statesController: _etats,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.ink,
            // Désactivé : ambre délavé plutôt que le gris Material, pour que
            // le bouton principal reste reconnaissable.
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
            disabledForegroundColor: AppColors.ink.withValues(alpha: 0.5),
            minimumSize: _tailleMinimale,
            shape: shape,
          ),
          child: child,
        ),
    };

    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _enfonce && !reduireAnimations ? AppMotion.pressedScale : 1,
      duration: AppMotion.press,
      curve: AppMotion.easeOut,
      child: button,
    );
  }
}
