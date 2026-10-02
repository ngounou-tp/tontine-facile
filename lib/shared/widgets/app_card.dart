import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Carte standard de l'app. Quand elle est cliquable, elle se tasse
/// légèrement sous le doigt : le retour tactile confirme l'appui avant même
/// la navigation. Le tassement passe par `onHighlightChanged` (et non un
/// simple appui du pointeur) pour ne pas se déclencher quand le doigt fait
/// défiler la liste.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  var _enfonce = false;

  @override
  Widget build(BuildContext context) {
    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    final shape = widget.borderColor == null
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(color: widget.borderColor!, width: widget.borderWidth),
          );
    final contenu = Padding(padding: widget.padding, child: widget.child);

    return AnimatedScale(
      scale: _enfonce && !reduireAnimations ? 0.985 : 1,
      duration: AppMotion.press,
      curve: AppMotion.easeOut,
      child: Card(
        color: widget.color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: widget.onTap == null
            ? contenu
            : InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (valeur) => setState(() => _enfonce = valeur),
                child: contenu,
              ),
      ),
    );
  }
}
