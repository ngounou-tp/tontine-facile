import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tour.dart';

/// Carte « tour en cours » du tableau de bord : bénéficiaire (le nom qui
/// reçoit la cagnotte de ce tour), date prévue, et accès à la collecte.
/// États vides : échéancier non généré, ou tous les tours remis.
class CurrentTourCard extends StatelessWidget {
  const CurrentTourCard({
    required this.tour,
    required this.noms,
    required this.membres,
    required this.tourGenere,
    this.onCollecter,
    super.key,
  });

  final Tour? tour;
  final List<Nom> noms;
  final List<Membre> membres;
  final bool tourGenere;
  final VoidCallback? onCollecter;

  Nom? _nom(String nomId) {
    for (final nom in noms) {
      if (nom.id == nomId) return nom;
    }
    return null;
  }

  String _beneficiaires(Nom? nom) {
    if (nom == null) return 'Nom inconnu';
    final noms = <String>[];
    for (final part in nom.parts) {
      for (final membre in membres) {
        if (membre.id == part.membreId) {
          noms.add(membre.nomComplet);
          break;
        }
      }
    }
    return noms.isEmpty ? nom.libelle : noms.join(' & ');
  }

  @override
  Widget build(BuildContext context) {
    if (!tourGenere) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.event_busy_outlined, color: AppColors.slate),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "L'échéancier n'a pas encore été généré. Attribuez les noms puis générez-le depuis Membres.",
                  style: AppTypography.secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final tourActuel = tour;
    if (tourActuel == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Tous les tours ont été remis. Bravo !', style: AppTypography.body),
        ),
      );
    }

    final date = tourActuel.datePrevue;
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCollecter,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.canvas,
                child: Text(
                  '${tourActuel.position}',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _beneficiaires(_nom(tourActuel.nomId)),
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('Prévu le $formatted', style: AppTypography.secondary),
                  ],
                ),
              ),
              if (onCollecter != null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, color: AppColors.slate),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
