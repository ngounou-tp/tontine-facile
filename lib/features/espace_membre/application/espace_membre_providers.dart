import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/cotisation.dart';
import '../../../domain/entities/declaration.dart';
import '../../../domain/entities/membre.dart';
import '../../../domain/entities/nom.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/enums/statut_cotisation.dart';
import '../../../domain/enums/statut_declaration.dart';
import '../../../domain/enums/statut_tour.dart';
import '../../../domain/services/calculateur_cotisation.dart';
import '../../auth/application/auth_providers.dart';
import '../../cotisations/application/cotisations_providers.dart';
import '../../echeancier/application/echeancier_providers.dart';
import '../../membres/application/membres_providers.dart';
import '../../tontine/application/tontine_providers.dart';

/// Fiche du membre connecté (jamais l'administratrice — voir le routeur,
/// qui redirige les administratrices vers /accueil), ou `null` tant que la
/// session ou la liste des membres n'est pas résolue.
///
/// La Firestore rule reste seule autorité : ces providers ne servent qu'à
/// piloter l'affichage, jamais à décider seuls si une action est permise —
/// une écriture refusée par les règles échoue quand même côté serveur.
final membreCourantProvider = Provider<Membre?>((ref) {
  final membreId = ref.watch(sessionProvider).value?.profil?.membreId;
  if (membreId == null) return null;
  final membres = ref.watch(membresProvider).value ?? const <Membre>[];
  for (final membre in membres) {
    if (membre.id == membreId) return membre;
  }
  return null;
});

/// Noms (et la fraction détenue) appartenant au membre connecté.
final mesNomsProvider = Provider<List<({Nom nom, double fraction})>>((ref) {
  final membre = ref.watch(membreCourantProvider);
  if (membre == null) return const [];
  final noms = ref.watch(nomsProvider).value ?? const <Nom>[];
  return [
    for (final nom in noms)
      for (final part in nom.parts)
        if (part.membreId == membre.id) (nom: nom, fraction: part.fraction),
  ];
});

/// Cotisations officielles du membre connecté (toutes origines, tous
/// statuts) — historique complet, triable par écran.
final mesCotisationsProvider = Provider<List<Cotisation>>((ref) {
  final membre = ref.watch(membreCourantProvider);
  if (membre == null) return const [];
  final cotisations = ref.watch(cotisationsProvider).value ?? const [];
  return cotisations.where((c) => c.membreId == membre.id).toList(growable: false);
});

/// Déclarations de paiement soumises par le membre connecté.
final mesDeclarationsProvider = Provider<List<Declaration>>((ref) {
  final membre = ref.watch(membreCourantProvider);
  if (membre == null) return const [];
  final declarations = ref.watch(declarationsProvider).value ?? const [];
  return declarations.where((d) => d.membreId == membre.id).toList(growable: false);
});

/// Prochain tour où l'un des noms du membre connecté sera bénéficiaire
/// (pas encore remis), trié par position — distinct du tour en cours de
/// collecte, qui concerne tous les noms.
final prochainTourMembreProvider = Provider<Tour?>((ref) {
  final mesNoms = ref.watch(mesNomsProvider);
  if (mesNoms.isEmpty) return null;
  final mesNomIds = mesNoms.map((e) => e.nom.id).toSet();
  final tours = ref.watch(toursProvider).value ?? const <Tour>[];
  final candidats = tours
      .where((t) => t.statut != StatutTour.remis && mesNomIds.contains(t.nomId))
      .toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  return candidats.isEmpty ? null : candidats.first;
});

const _calculateur = CalculateurCotisation();

/// Situation d'un nom détenu par le membre connecté vis-à-vis du tour en
/// cours de collecte : montant dû pour sa fraction, montant déjà versé
/// (cotisations validées), déclaration en attente éventuelle, et
/// éligibilité à déclarer un nouveau paiement.
///
/// [peutDeclarer] reflète uniquement l'état des données affichées — la
/// création réelle est encore et toujours soumise aux règles Firestore
/// (déclaration sur un nom qu'on détient, tour en cours, statut
/// `enAttente`). Les règles Firestore n'autorisent le membre qu'à *créer*
/// une déclaration (jamais à modifier celle déjà refusée) : une déclaration
/// contestée redevient donc automatiquement déclarable — [peutDeclarer] ne
/// dépend que de `declarationEnAttente`, pas de [declarationContestee].
class SituationNomTourActuel {
  const SituationNomTourActuel({
    required this.nom,
    required this.fraction,
    required this.montantDu,
    required this.montantVerse,
    required this.declarationEnAttente,
    required this.declarationContestee,
    this.motifContestation,
  });

  final Nom nom;
  final double fraction;
  final int montantDu;
  final int montantVerse;
  final bool declarationEnAttente;
  final bool declarationContestee;
  final String? motifContestation;

  bool get solde => montantVerse >= montantDu;
  bool get peutDeclarer => !solde && !declarationEnAttente;
}

/// Situation de chaque nom du membre connecté pour le tour en cours —
/// liste vide si aucun tour n'est en cours ou si le membre ne détient
/// aucun nom.
final mesSituationsTourActuelProvider = Provider<List<SituationNomTourActuel>>((ref) {
  final tontine = ref.watch(tontineProvider).value;
  final tour = ref.watch(tourActuelProvider);
  final mesNoms = ref.watch(mesNomsProvider);
  if (tontine == null || tour == null || mesNoms.isEmpty) return const [];

  final membre = ref.watch(membreCourantProvider);
  final cotisations = ref.watch(cotisationsProvider).value ?? const [];
  final declarations = ref.watch(declarationsProvider).value ?? const [];

  return [
    for (final detenu in mesNoms)
      () {
        final mesDeclarationsPourCeNom = declarations.where((d) =>
            d.tourId == tour.id && d.nomId == detenu.nom.id && d.membreId == membre!.id);
        final derniereContestee = mesDeclarationsPourCeNom
            .where((d) => d.statut == StatutDeclaration.contestee)
            .fold<Declaration?>(
              null,
              (plusRecente, d) => plusRecente == null || d.createdAt.isAfter(plusRecente.createdAt)
                  ? d
                  : plusRecente,
            );
        return SituationNomTourActuel(
          nom: detenu.nom,
          fraction: detenu.fraction,
          montantDu: _calculateur.calculerMontantDuPourMembre(
            tontine: tontine,
            nom: detenu.nom,
            membreId: membre!.id,
          ),
          montantVerse: cotisations
              .where((c) =>
                  c.tourId == tour.id &&
                  c.nomId == detenu.nom.id &&
                  c.membreId == membre.id &&
                  c.statut == StatutCotisation.validee)
              .fold<int>(0, (somme, c) => somme + c.montantVerse),
          declarationEnAttente:
              mesDeclarationsPourCeNom.any((d) => d.statut == StatutDeclaration.enAttente),
          declarationContestee: derniereContestee != null,
          motifContestation: derniereContestee?.motifContestation,
        );
      }(),
  ];
});
