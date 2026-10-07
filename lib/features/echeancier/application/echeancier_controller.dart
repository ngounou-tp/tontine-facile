import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/nom.dart';
import '../../../domain/entities/tontine.dart';
import '../../../domain/services/generateur_echeancier.dart';
import '../../auth/application/auth_providers.dart';

/// État partagé de la génération de l'échéancier. Les écrans peuvent
/// écouter [echeancierControllerProvider] pour désactiver leur bouton
/// pendant la requête et afficher une erreur métier.
final echeancierControllerProvider =
    AsyncNotifierProvider<EcheancierController, void>(EcheancierController.new);

/// Génère le programme (tours) d'une tontine à partir de ses noms, via
/// [GenerateurEcheancier], puis persiste chaque [Tour] généré.
class EcheancierController extends AsyncNotifier<void> {
  static const _generateur = GenerateurEcheancier();

  @override
  Future<void> build() async {}

  Future<void> genererEcheancier({
    required Tontine tontine,
    required List<Nom> noms,
  }) async {
    state = const AsyncLoading();
    try {
      final tontines = ref.read(tontineRepositoryProvider);
      final tours = _generateur.generer(
        tontine: tontine,
        noms: noms,
        nouvelId: (_) => tontines.nouvelIdTour(tontine.id),
      );
      // Une seule requête : l'échéancier est créé entier ou pas du tout.
      await tontines.saveTours(tontine.id, tours);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
