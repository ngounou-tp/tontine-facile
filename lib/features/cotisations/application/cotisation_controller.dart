import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/nom.dart';
import '../../../domain/entities/preuve.dart';
import '../../../domain/entities/tontine.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/services/enregistrement_cotisation.dart';
import '../../auth/application/auth_providers.dart';
import 'tour_refresh.dart';

/// État partagé de la saisie d'une cotisation officielle par
/// l'administratrice. Les écrans peuvent écouter
/// [cotisationControllerProvider] pour désactiver leur bouton pendant la
/// requête et afficher une erreur métier.
final cotisationControllerProvider =
    AsyncNotifierProvider<CotisationController, void>(CotisationController.new);

/// Enregistre une cotisation saisie directement par l'administratrice
/// ([EnregistrementCotisation]), puis rafraîchit l'état du tour concerné —
/// le marque remis dès que tous les noms ont intégralement réglé
/// ([CalculateurEtatTour]) et démarre le tour suivant le cas échéant.
class CotisationController extends AsyncNotifier<void> {
  static const _enregistrement = EnregistrementCotisation();

  @override
  Future<void> build() async {}

  Future<void> saisirCotisation({
    required String tontineId,
    required Tontine tontine,
    required Tour tour,
    required Nom nom,
    required String membreId,
    required String adminUid,
    required int montantVerse,
    required DateTime datePaiement,
    Uint8List? preuveBytes,
    String? motifException,
    bool exonererPenalite = false,
  }) async {
    state = const AsyncLoading();
    try {
      final tontines = ref.read(tontineRepositoryProvider);

      String? preuveId;
      if (preuveBytes != null) {
        preuveId = tontines.nouvelIdPreuve(tontineId);
        await tontines.savePreuve(
          tontineId,
          Preuve(
            id: preuveId,
            imageEncodee: base64Encode(preuveBytes),
            tailleOctets: preuveBytes.lengthInBytes,
            createdAt: DateTime.now(),
          ),
        );
      }

      final cotisation = _enregistrement.enregistrer(
        id: tontines.nouvelIdCotisation(tontineId),
        tontine: tontine,
        tour: tour,
        nom: nom,
        membreId: membreId,
        adminUid: adminUid,
        montantVerse: montantVerse,
        datePaiement: datePaiement,
        preuveId: preuveId,
        motifException: motifException,
        exonererPenalite: exonererPenalite,
      );
      await tontines.saveCotisation(tontineId, cotisation);
      await rafraichirTours(tontines: tontines, tontineId: tontineId, tontine: tontine, tour: tour);

      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
