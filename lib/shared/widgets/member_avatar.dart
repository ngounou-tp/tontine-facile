import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// `Rose Domche Ateba` → `RA` ; `Alice` → `A` ; nom vide → `?`.
String initiales(String nomComplet) {
  final mots = nomComplet.trim().split(RegExp(r'\s+'));
  if (mots.isEmpty || mots.first.isEmpty) return '?';
  final premiere = mots.first[0];
  final derniere = mots.length > 1 ? mots.last[0] : '';
  return (premiere + derniere).toUpperCase();
}

/// Avatar à initiales d'un membre. La teinte est dérivée du nom, donc
/// stable d'un écran à l'autre : on reconnaît « Rose » à sa couleur dans la
/// liste des membres comme dans la collecte, sans lire.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({required this.nomComplet, this.size = 40, super.key});

  final String nomComplet;
  final double size;

  static Color teinteDe(String nomComplet) {
    var hash = 0;
    for (final unit in nomComplet.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final teinte = teinteDe(nomComplet);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: teinte.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Text(
        initiales(nomComplet),
        style: AppTypography.micro.copyWith(
          color: teinte,
          fontSize: size * 0.36,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
