import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tontine.dart';
import '../../auth/application/auth_providers.dart';

/// État partagé de la création de tontine. Les écrans peuvent écouter
/// [creationTontineControllerProvider] pour désactiver leur bouton pendant
/// la requête et afficher une erreur métier avec `state.whenOrNull(error:
/// ...)`.
final creationTontineControllerProvider =
    AsyncNotifierProvider<CreationTontineController, void>(
  CreationTontineController.new,
);

/// Crée la tontine d'une administratrice déjà authentifiée mais sans profil
/// (arrivée via `InscriptionService.creerCompteSansTontine`, typiquement
/// routée vers `/creer-tontine`).
///
/// La validation métier ([ValidationTontine]) et l'orchestration Firestore
/// (tontine, membre, invitation auto-réclamée, profil) vivent dans
/// `InscriptionService.creerTontinePourAdmin`, qui partage sa logique avec
/// `inscrireAdmin` — ce contrôleur n'est qu'une fine façade Riverpod
/// au-dessus, sur le même modèle qu'`AuthController`.
class CreationTontineController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Renvoie l'identifiant du groupe créé.
  Future<String> creerTontine({
    required String nomCompletAdmin,
    required Tontine tontineSansId,
  }) => _run(
        () => ref.read(inscriptionServiceProvider).creerTontine(
              nomCompletAdmin: nomCompletAdmin,
              tontineSansId: tontineSansId,
            ),
      );

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
}
