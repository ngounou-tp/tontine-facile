import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/tontine_repository.dart';
import '../../../domain/entities/invitation.dart';
import '../../../domain/entities/membre.dart';
import '../../../domain/entities/nom.dart';
import '../../../domain/entities/part.dart';
import '../../../domain/rules/validation_parts.dart';
import '../../auth/application/auth_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../l10n/l10n.dart';

/// État partagé des actions de gestion des membres et des parts. Les écrans
/// peuvent écouter [membresControllerProvider] pour désactiver leur bouton
/// pendant la requête et afficher une erreur métier avec
/// `state.whenOrNull(error: ...)`.
final membresControllerProvider =
    AsyncNotifierProvider<MembresController, void>(MembresController.new);

/// Ajoute, modifie et désactive des membres, et assigne les parts d'un nom
/// (tour de la tontine) à leurs détenteurs.
class MembresController extends AsyncNotifier<void> {
  TontineRepository get _tontines => ref.read(tontineRepositoryProvider);

  @override
  Future<void> build() async {}

  /// Ajoute un membre placeholder (sans compte associé), sans générer
  /// d'invitation. Réservé aux cas où le code sera généré plus tard ; pour
  /// l'ajout standard depuis l'écran « Ajouter un membre », voir
  /// [inviterMembre].
  Future<Membre> ajouterMembre({
    required String tontineId,
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) => _run(
        () => _tontines.creerMembrePlaceholder(
          tontineId,
          nomComplet: nomComplet,
          email: email,
          whatsapp: whatsapp,
        ),
      );

  /// Ajoute un membre placeholder et génère dans la foulée son invitation
  /// nominative (voir `InscriptionService.inviterMembre`) : c'est ce code
  /// que l'administratrice transmet au nouveau membre pour qu'il réclame sa
  /// fiche à l'inscription.
  Future<Invitation> inviterMembre({
    required String tontineId,
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) => _run(
        () => ref.read(inscriptionServiceProvider).inviterMembre(
              tontineId: tontineId,
              nomComplet: nomComplet,
              email: email,
              whatsapp: whatsapp,
            ),
      );

  /// Ajoute un membre (comme [inviterMembre]) puis lui attribue directement
  /// [nombreDeNoms] noms — un multiple de `0.5` : chaque unité entière
  /// devient un nom complet lui appartenant seul ; un reste d'une demie
  /// complète un nom déjà à moitié attribué (s'il en existe un) ou en ouvre
  /// un nouveau en attente d'un second détenteur (voir [_attribuerNoms]).
  ///
  /// Contrairement à [creerNom]/[assignerParts], cette attribution
  /// automatique n'exige pas que chaque nom touché somme à 1 : un nom à
  /// moitié attribué, en attente d'un second membre, est un état
  /// intermédiaire valide ici — [MembresPage] n'autorise la génération de
  /// l'échéancier qu'une fois tous les noms complets.
  Future<Invitation> inviterMembreAvecNoms({
    required String tontineId,
    required String nomComplet,
    String? email,
    String? whatsapp,
    required double nombreDeNoms,
  }) => _run(() async {
        final invitation = await ref.read(inscriptionServiceProvider).inviterMembre(
              tontineId: tontineId,
              nomComplet: nomComplet,
              email: email,
              whatsapp: whatsapp,
            );
        await _attribuerNoms(
          tontineId: tontineId,
          membreId: invitation.membreId,
          nombreDeNoms: nombreDeNoms,
        );
        return invitation;
      });

  /// Attribue [nombreDeNoms] noms supplémentaires à un membre déjà
  /// enregistré — même logique que la part « noms » de
  /// [inviterMembreAvecNoms], utilisable après coup depuis sa fiche.
  Future<void> attribuerNomsSupplementaires({
    required String tontineId,
    required String membreId,
    required double nombreDeNoms,
  }) => _runVoid(
        () => _attribuerNoms(
          tontineId: tontineId,
          membreId: membreId,
          nombreDeNoms: nombreDeNoms,
        ),
      );

  Future<void> _attribuerNoms({
    required String tontineId,
    required String membreId,
    required double nombreDeNoms,
  }) async {
    if (nombreDeNoms <= 0) return;
    final tontine = await _tontines.getTontine(tontineId);
    final noms = await _tontines.getNoms(tontineId);

    if (tontine != null) {
      final completeraUnNomExistant = (nombreDeNoms % 1 >= 0.5 - 1e-6) &&
          noms.any((nom) {
            final somme = nom.parts.fold<double>(0, (total, part) => total + part.fraction);
            return (somme - 0.5).abs() < 1e-6;
          });
      final demiRestant = nombreDeNoms % 1 >= 0.5 - 1e-6 && !completeraUnNomExistant ? 1 : 0;
      final nouveauxNoms = nombreDeNoms.truncate() + demiRestant;
      if (noms.length + nouveauxNoms > tontine.nombreDeNoms) {
        throw NamesQuotaExceededException(tontine.nombreDeNoms);
      }
    }

    var prochainePosition = noms.length + 1;
    var restant = nombreDeNoms;

    while (restant >= 1) {
      await _tontines.saveNom(
        tontineId,
        Nom(
          id: _tontines.nouvelIdNom(tontineId),
          position: prochainePosition,
          libelle: L10n.current.defaultNameLabel(prochainePosition),
          parts: [Part(membreId: membreId, fraction: 1)],
        ),
      );
      prochainePosition += 1;
      restant -= 1;
    }

    if (restant >= 0.5) {
      Nom? nomIncomplet;
      for (final nom in noms) {
        final somme = nom.parts.fold<double>(0, (total, part) => total + part.fraction);
        if ((somme - 0.5).abs() < 1e-6) {
          nomIncomplet = nom;
          break;
        }
      }
      if (nomIncomplet != null) {
        await _tontines.saveNom(
          tontineId,
          Nom(
            id: nomIncomplet.id,
            position: nomIncomplet.position,
            libelle: nomIncomplet.libelle,
            parts: [...nomIncomplet.parts, Part(membreId: membreId, fraction: 0.5)],
          ),
        );
      } else {
        await _tontines.saveNom(
          tontineId,
          Nom(
            id: _tontines.nouvelIdNom(tontineId),
            position: prochainePosition,
            libelle: L10n.current.defaultNameLabel(prochainePosition),
            parts: [Part(membreId: membreId, fraction: 0.5)],
          ),
        );
      }
    }
  }

  /// Modifie les coordonnées d'un membre existant (nom, email, whatsapp).
  /// Conserve son `id`, son `uid` et son statut `actif` tels quels.
  Future<void> modifierMembre({
    required String tontineId,
    required Membre membre,
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) => _runVoid(
        () => _tontines.saveMembre(
          tontineId,
          Membre(
            id: membre.id,
            nomComplet: nomComplet,
            email: email,
            whatsapp: whatsapp,
            uid: membre.uid,
            actif: membre.actif,
            codeInvitation: membre.codeInvitation,
          ),
        ),
      );

  /// Désactive un membre : conserve son historique (cotisations,
  /// déclarations passées) sans le supprimer.
  Future<void> desactiverMembre({
    required String tontineId,
    required Membre membre,
  }) => _basculerActif(tontineId: tontineId, membre: membre, actif: false);

  /// Réactive un membre précédemment désactivé.
  Future<void> reactiverMembre({
    required String tontineId,
    required Membre membre,
  }) => _basculerActif(tontineId: tontineId, membre: membre, actif: true);

  Future<void> _basculerActif({
    required String tontineId,
    required Membre membre,
    required bool actif,
  }) => _runVoid(
        () => _tontines.saveMembre(
          tontineId,
          Membre(
            id: membre.id,
            nomComplet: membre.nomComplet,
            email: membre.email,
            whatsapp: membre.whatsapp,
            uid: membre.uid,
            actif: actif,
            codeInvitation: membre.codeInvitation,
          ),
        ),
      );

  /// Crée un nouveau nom (part/tour de la tontine) avec ses détenteurs de
  /// part initiaux. Le libellé n'est pas personnalisable : il est toujours
  /// généré comme « Nom [position] ». [parts] est validé via
  /// [ValidationParts] (fractions dans `]0, 1]`, membres renseignés, somme
  /// égale à 1) avant toute écriture — pour une attribution automatique
  /// tolérant les noms à moitié complets, voir [inviterMembreAvecNoms].
  Future<Nom> creerNom({
    required String tontineId,
    required int position,
    required List<Part> parts,
  }) => _run(() async {
        const ValidationParts().valider(parts);
        final nom = Nom(
          id: _tontines.nouvelIdNom(tontineId),
          position: position,
          libelle: L10n.current.defaultNameLabel(position),
          parts: parts,
        );
        await _tontines.saveNom(tontineId, nom);
        return nom;
      });

  /// Réassigne les détenteurs de part d'un nom existant. [parts] est validé
  /// via [ValidationParts] avant toute écriture.
  Future<void> assignerParts({
    required String tontineId,
    required Nom nom,
    required List<Part> parts,
  }) => _runVoid(() async {
        const ValidationParts().valider(parts);
        await _tontines.saveNom(
          tontineId,
          Nom(id: nom.id, position: nom.position, libelle: nom.libelle, parts: parts),
        );
      });

  Future<T> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _runVoid(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
