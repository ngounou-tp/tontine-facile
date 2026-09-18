import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/cotisation.dart';
import '../../../domain/entities/declaration.dart';
import '../../../domain/entities/nom.dart';
import '../../../domain/entities/preuve.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/enums/statut_cotisation.dart';
import '../../../domain/enums/statut_declaration.dart';
import '../../../domain/enums/statut_tour.dart';
import '../../../domain/services/calculateur_cotisation.dart';
import '../../auth/application/auth_providers.dart';
import '../../echeancier/application/echeancier_providers.dart';
import '../../membres/application/membres_providers.dart';
import '../../tontine/application/tontine_providers.dart';

/// Cotisations officielles de la tontine courante, mises à jour en direct.
/// Liste vide tant que la tontine courante n'est pas résolue.
final cotisationsProvider = StreamProvider<List<Cotisation>>((ref) {
  final tontineId = ref.watch(currentTontineIdProvider);
  if (tontineId == null) return Stream.value(const []);
  return ref.watch(tontineRepositoryProvider).watchCotisations(tontineId);
});

/// Déclarations de paiement des membres de la tontine courante, mises à
/// jour en direct. Liste vide tant que la tontine courante n'est pas
/// résolue.
final declarationsProvider = StreamProvider<List<Declaration>>((ref) {
  final tontineId = ref.watch(currentTontineIdProvider);
  if (tontineId == null) return Stream.value(const []);
  return ref.watch(tontineRepositoryProvider).watchDeclarations(tontineId);
});

/// Déclarations en attente de traitement par l'administratrice — pilote la
/// bannière du tableau de bord et l'écran de traitement des déclarations.
final declarationsEnAttenteProvider = Provider<List<Declaration>>((ref) {
  final declarations = ref.watch(declarationsProvider).value ?? const [];
  return declarations.where((d) => d.statut == StatutDeclaration.enAttente).toList(growable: false);
});

/// Tour en cours de la tontine courante (au plus un à la fois — voir
/// `GenerateurEcheancier`), ou `null` si l'échéancier n'a pas encore été
/// généré ou si tous les tours ont été remis.
final tourActuelProvider = Provider<Tour?>((ref) {
  final tours = ref.watch(toursProvider).value ?? const [];
  for (final tour in tours) {
    if (tour.statut == StatutTour.enCours) return tour;
  }
  return null;
});

/// Statut de paiement d'un nom pour le tour en cours : agrège ses
/// cotisations validées face au montant dû (voir `CalculateurCotisation`).
enum StatutPaiementNom { paye, partiel, impaye }

/// Situation d'un [nom] vis-à-vis du [tourActuelProvider] : montant dû,
/// montant déjà versé (cotisations validées uniquement — une déclaration en
/// attente n'y contribue pas tant qu'elle n'est pas traitée), et retard
/// éventuel par rapport à la date prévue du tour.
class EtatCotisationNom {
  const EtatCotisationNom({
    required this.nom,
    required this.montantDu,
    required this.montantVerse,
    required this.enRetard,
  });

  final Nom nom;
  final int montantDu;
  final int montantVerse;
  final bool enRetard;

  int get resteADu => montantDu - montantVerse;

  StatutPaiementNom get statut {
    if (montantVerse >= montantDu) return StatutPaiementNom.paye;
    if (montantVerse > 0) return StatutPaiementNom.partiel;
    return StatutPaiementNom.impaye;
  }
}

const _calculateur = CalculateurCotisation();

/// Situation de chaque nom vis-à-vis du tour en cours — liste vide si
/// l'échéancier n'a pas encore été généré ou si tous les tours sont remis.
final etatsNomsTourActuelProvider = Provider<List<EtatCotisationNom>>((ref) {
  final tontine = ref.watch(tontineProvider).value;
  final tour = ref.watch(tourActuelProvider);
  if (tontine == null || tour == null) return const [];
  final noms = ref.watch(nomsProvider).value ?? const [];
  final cotisations = ref.watch(cotisationsProvider).value ?? const [];
  final enRetard = DateTime.now().isAfter(tour.datePrevue);

  return [
    for (final nom in noms)
      EtatCotisationNom(
        nom: nom,
        montantDu: _calculateur.calculerMontantDu(tontine: tontine, nom: nom),
        montantVerse: cotisations
            .where((c) =>
                c.tourId == tour.id && c.nomId == nom.id && c.statut == StatutCotisation.validee)
            .fold<int>(0, (somme, c) => somme + c.montantVerse),
        enRetard: enRetard,
      ),
  ];
});

/// Montant total attendu sur le tour en cours (somme des montants dus de
/// chaque nom).
final totalAttenduTourActuelProvider = Provider<int>((ref) {
  final etats = ref.watch(etatsNomsTourActuelProvider);
  return etats.fold<int>(0, (somme, etat) => somme + etat.montantDu);
});

/// Montant total collecté (cotisations validées) sur le tour en cours.
final totalCollecteTourActuelProvider = Provider<int>((ref) {
  final etats = ref.watch(etatsNomsTourActuelProvider);
  return etats.fold<int>(0, (somme, etat) => somme + etat.montantVerse);
});

/// Noms n'ayant pas encore intégralement réglé le tour en cours (partiel ou
/// impayé), triés par ordre de nom — pilote la liste de collecte de
/// l'administratrice.
final nomsNonSoldesTourActuelProvider = Provider<List<EtatCotisationNom>>((ref) {
  final etats = ref.watch(etatsNomsTourActuelProvider);
  return etats.where((etat) => etat.statut != StatutPaiementNom.paye).toList(growable: false);
});

/// Preuve (photo compressée) désignée par [preuveId], récupérée une fois —
/// un document `preuves` est immuable après création (voir
/// `firestore.rules`), inutile de le suivre en direct.
final preuveProvider = FutureProvider.family<Preuve?, String>((ref, preuveId) async {
  final tontineId = ref.watch(currentTontineIdProvider);
  if (tontineId == null) return null;
  final preuves = await ref.watch(tontineRepositoryProvider).getPreuves(tontineId);
  for (final preuve in preuves) {
    if (preuve.id == preuveId) return preuve;
  }
  return null;
});
