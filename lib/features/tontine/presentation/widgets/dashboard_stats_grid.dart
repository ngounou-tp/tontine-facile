import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Grille « en un coup d'œil » du tableau de bord : membres actifs, noms
/// attribués, avancement de la tontine (tours remis) et répartition des
/// paiements à temps / en retard (sur l'historique complet des cotisations
/// validées). La collecte du tour en cours n'y figure pas : elle est déjà le
/// chiffre principal de la carte du tour.
class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({
    required this.membresActifs,
    required this.nomsAttribues,
    required this.nomsAttendus,
    required this.toursRemis,
    required this.toursTotal,
    required this.paiementsATemps,
    required this.paiementsEnRetard,
    super.key,
  });

  final int membresActifs;
  final int nomsAttribues;
  final int nomsAttendus;
  final int toursRemis;
  final int toursTotal;
  final int paiementsATemps;
  final int paiementsEnRetard;

  @override
  Widget build(BuildContext context) {
    final tuiles = [
      _StatTile(
        icon: Icons.groups_outlined,
        valeur: '$membresActifs',
        libelle: membresActifs > 1 ? 'Membres actifs' : 'Membre actif',
      ),
      _StatTile(
        icon: Icons.badge_outlined,
        valeur: '$nomsAttribues/$nomsAttendus',
        libelle: 'Noms attribués',
        alerte: nomsAttribues < nomsAttendus,
      ),
      _StatTile(
        icon: Icons.flag_outlined,
        valeur: toursTotal == 0 ? '—' : '$toursRemis/$toursTotal',
        libelle: 'Tours remis',
      ),
      _StatTile(
        icon: Icons.schedule_outlined,
        valeur: '$paiementsATemps / $paiementsEnRetard',
        libelle: 'À temps / en retard',
        alerte: paiementsEnRetard > 0,
      ),
    ];
    // Deux colonnes de hauteur égale, calculées par le contenu plutôt que
    // par un ratio fixe : rien n'est coupé avec une police système agrandie.
    return Column(
      children: [
        for (var ligne = 0; ligne < tuiles.length; ligne += 2) ...[
          if (ligne > 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tuiles[ligne]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: tuiles[ligne + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.valeur,
    required this.libelle,
    this.alerte = false,
  });

  final IconData icon;
  final String valeur;
  final String libelle;

  /// La statistique demande une action (noms manquants, retards) : l'icône
  /// passe en ambre, sans alarmer davantage.
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: alerte ? AppColors.warning : AppColors.indigo),
            const SizedBox(height: AppSpacing.sm),
            Text(
              valeur,
              style: AppTypography.amount.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(libelle, style: AppTypography.secondary, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
