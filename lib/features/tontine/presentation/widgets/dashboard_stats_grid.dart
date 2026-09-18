import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Grille de statistiques du tableau de bord : membres actifs, noms
/// attribués, taux de collecte du tour en cours et répartition des
/// paiements à temps / en retard (sur l'historique complet des
/// cotisations validées).
class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({
    required this.membresActifs,
    required this.nomsAttribues,
    required this.nomsAttendus,
    required this.tauxCollecte,
    required this.paiementsATemps,
    required this.paiementsEnRetard,
    super.key,
  });

  final int membresActifs;
  final int nomsAttribues;
  final int nomsAttendus;
  final double? tauxCollecte;
  final int paiementsATemps;
  final int paiementsEnRetard;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.1,
      children: [
        _StatTile(
          icon: Icons.groups_outlined,
          couleur: AppColors.indigo,
          valeur: '$membresActifs',
          libelle: membresActifs > 1 ? 'Membres actifs' : 'Membre actif',
        ),
        _StatTile(
          icon: Icons.badge_outlined,
          couleur: AppColors.accent,
          valeur: '$nomsAttribues/$nomsAttendus',
          libelle: 'Noms attribués',
        ),
        _StatTile(
          icon: Icons.pie_chart_outline,
          couleur: AppColors.success,
          valeur: tauxCollecte == null ? '—' : '${(tauxCollecte! * 100).round()} %',
          libelle: 'Collecte du tour',
        ),
        _StatTile(
          icon: Icons.schedule_outlined,
          couleur: paiementsEnRetard > 0 ? AppColors.warning : AppColors.success,
          valeur: '$paiementsATemps / $paiementsEnRetard',
          libelle: 'À temps / en retard',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.couleur,
    required this.valeur,
    required this.libelle,
  });

  final IconData icon;
  final Color couleur;
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Liseré de couleur : identifie la statistique d'un coup d'œil,
            // sans dépendre uniquement de la couleur (souvent trop subtile)
            // de la petite icône.
            Container(width: 4, color: couleur),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: couleur.withValues(alpha: 0.12),
                      child: Icon(icon, color: couleur, size: 15),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            valeur,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(libelle, style: AppTypography.micro, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
