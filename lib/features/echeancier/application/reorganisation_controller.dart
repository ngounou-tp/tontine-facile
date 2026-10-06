import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tontine.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/services/reorganisateur_tours.dart';
import '../../auth/application/auth_providers.dart';

/// État partagé de la réorganisation de l'échéancier. Les écrans peuvent
/// écouter [reorganisationControllerProvider] pour désactiver leurs
/// interactions pendant la requête et afficher une erreur métier.
final reorganisationControllerProvider =
    AsyncNotifierProvider<ReorganisationController, void>(ReorganisationController.new);

/// Déplace un tour non encore remis vers une autre position
/// ([ReorganisateurTours]) : recalcule les dates des tours affectés, trace
/// le changement, puis persiste tours et changements modifiés.
class ReorganisationController extends AsyncNotifier<void> {
  static const _reorganisateur = ReorganisateurTours();

  @override
  Future<void> build() async {}

  Future<void> deplacer({
    required String tontineId,
    required Tontine tontine,
    required List<Tour> tours,
    required int anciennePosition,
    required int nouvellePosition,
    required String motif,
    required String auteurUid,
  }) async {
    state = const AsyncLoading();
    try {
      final resultat = _reorganisateur.reorganiser(
        tontine: tontine,
        tours: tours,
        anciennePosition: anciennePosition,
        nouvellePosition: nouvellePosition,
        motif: motif,
        auteurUid: auteurUid,
      );
      final tontines = ref.read(tontineRepositoryProvider);
      await tontines.reorganiserTours(
        tontineId,
        tours: resultat.tours,
        changements: resultat.changements,
        motif: motif.trim(),
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
