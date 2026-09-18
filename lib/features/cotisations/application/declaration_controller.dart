import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/declaration.dart';
import '../../../domain/entities/nom.dart';
import '../../../domain/entities/preuve.dart';
import '../../../domain/entities/tontine.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/enums/statut_declaration.dart';
import '../../../domain/rules/validation_declaration.dart';
import '../../../domain/services/traitement_declaration.dart';
import '../../auth/application/auth_providers.dart';
import 'tour_refresh.dart';

/// État partagé du dépôt et du traitement des déclarations de paiement.
/// Les écrans peuvent écouter [declarationControllerProvider] pour
/// désactiver leurs actions pendant la requête et afficher une erreur
/// métier — la Firestore rule reste la seule autorité réelle : un refus
/// serveur remonte ici comme n'importe quelle autre erreur.
final declarationControllerProvider =
    AsyncNotifierProvider<DeclarationController, void>(DeclarationController.new);

class DeclarationController extends AsyncNotifier<void> {
  static const _validationDeclaration = ValidationDeclaration();
  static const _traitement = TraitementDeclaration();

  @override
  Future<void> build() async {}

  /// Dépôt d'une déclaration par un membre : preuve obligatoire, montant
  /// possiblement partiel, ne modifie aucun total officiel (voir
  /// `ValidationDeclaration`).
  Future<void> declarerPaiement({
    required String tontineId,
    required Tour tour,
    required Nom nom,
    required String membreId,
    required int montantDeclare,
    required DateTime datePaiement,
    required Uint8List preuveBytes,
  }) async {
    state = const AsyncLoading();
    try {
      final tontines = ref.read(tontineRepositoryProvider);

      final preuveId = tontines.nouvelIdPreuve(tontineId);
      await tontines.savePreuve(
        tontineId,
        Preuve(
          id: preuveId,
          imageEncodee: base64Encode(preuveBytes),
          tailleOctets: preuveBytes.lengthInBytes,
          createdAt: DateTime.now(),
        ),
      );

      final declaration = Declaration(
        id: tontines.nouvelIdDeclaration(tontineId),
        tourId: tour.id,
        nomId: nom.id,
        membreId: membreId,
        montantDeclare: montantDeclare,
        datePaiement: datePaiement,
        preuveId: preuveId,
        statut: StatutDeclaration.enAttente,
        createdAt: DateTime.now(),
      );
      _validationDeclaration.valider(declaration: declaration, nom: nom, tour: tour);
      await tontines.saveDeclaration(tontineId, declaration);

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Validation par l'administratrice : crée la cotisation officielle
  /// correspondante, marque la déclaration validée, puis rafraîchit
  /// l'état du tour comme pour une saisie directe.
  Future<void> validerDeclaration({
    required String tontineId,
    required Declaration declaration,
    required Tontine tontine,
    required Nom nom,
    required Tour tour,
    required String adminUid,
  }) async {
    state = const AsyncLoading();
    try {
      final tontines = ref.read(tontineRepositoryProvider);
      final cotisation = _traitement.valider(
        declaration: declaration,
        tontine: tontine,
        nom: nom,
        tour: tour,
        adminUid: adminUid,
      );
      await tontines.saveCotisation(tontineId, cotisation);
      await tontines.saveDeclaration(tontineId, _traitement.validerDeclaration(declaration: declaration));
      await rafraichirTours(tontines: tontines, tontineId: tontineId, tontine: tontine, tour: tour);

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  /// Refus par l'administratrice : exige un motif, ne modifie aucun total
  /// officiel.
  Future<void> refuserDeclaration({
    required String tontineId,
    required Declaration declaration,
    required String motif,
  }) async {
    state = const AsyncLoading();
    try {
      final tontines = ref.read(tontineRepositoryProvider);
      final declarationMaj = _traitement.contester(declaration: declaration, motif: motif);
      await tontines.saveDeclaration(tontineId, declarationMaj);

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
