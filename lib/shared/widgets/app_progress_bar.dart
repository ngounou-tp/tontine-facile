import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Jauge de progression qui se remplit à l'affichage puis glisse vers sa
/// nouvelle valeur quand les données changent (une cotisation enregistrée
/// fait avancer la barre sous les yeux de l'administratrice). Sans
/// animation si le système demande de réduire les mouvements.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.color = AppColors.indigo,
    this.trackColor = AppColors.canvas,
    this.height = 8,
    super.key,
  });

  /// Entre 0 et 1 (les valeurs hors bornes sont ramenées dans l'intervalle).
  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cible = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: cible),
      duration: reduireAnimations ? Duration.zero : AppMotion.progress,
      curve: AppMotion.easeOut,
      builder: (context, progression, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: progression,
          minHeight: height,
          backgroundColor: trackColor,
          color: color,
        ),
      ),
    );
  }
}
