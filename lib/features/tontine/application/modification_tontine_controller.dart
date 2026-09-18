import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tontine.dart';
import '../../../domain/rules/validation_tontine.dart';
import '../../auth/application/auth_providers.dart';

/// État partagé de la modification de la tontine courante. Les écrans
/// peuvent écouter [modificationTontineControllerProvider] pour désactiver
/// leur bouton pendant la requête et afficher une erreur métier.
final modificationTontineControllerProvider =
    AsyncNotifierProvider<ModificationTontineController, void>(
  ModificationTontineController.new,
);

/// Met à jour les champs modifiables d'une tontine existante (nom, montant
/// par nom, nombre de noms, pénalité, délai de grâce). La périodicité et le
/// mode de répartition des parts restent figés après création : les
/// modifier invaliderait l'échéancier déjà généré et les calculs de parts
/// déjà en cours — voir `CreerTontinePage`.
class ModificationTontineController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> modifierTontine(Tontine tontine) async {
    state = const AsyncLoading();
    try {
      const ValidationTontine().valider(tontine);
      await ref.read(tontineRepositoryProvider).saveTontine(tontine);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
