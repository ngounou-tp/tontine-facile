import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/inscription_service.dart';
import '../../../domain/entities/app_user.dart';
import 'auth_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// Actions d'authentification et de groupe déclenchées par les écrans ;
/// expose l'état « en cours » pour désactiver les boutons pendant une
/// requête. Les erreurs sont relancées pour être affichées par l'écran.
class AuthController extends AsyncNotifier<void> {
  InscriptionService get _service => ref.read(inscriptionServiceProvider);

  @override
  Future<void> build() async {}

  Future<AppUser> connecter({required String email, required String password}) =>
      _run(() => _service.connecter(email: email, password: password));

  /// Inscription par email, avec un code d'invitation éventuel.
  Future<IssueInscription> inscrire({
    required String email,
    required String password,
    String? codeInvitation,
  }) =>
      _run(() => _service.inscrire(email: email, password: password, codeInvitation: codeInvitation));

  Future<String> rejoindreAvecCode(String codeInvitation) =>
      _run(() => _service.rejoindreAvecCode(codeInvitation));

  Future<AppUser?> connecterAvecGoogle() => _run(_service.connecterAvecGoogle);

  Future<AppUser?> connecterAvecApple() => _run(_service.connecterAvecApple);

  Future<void> choisirGroupe(String groupeId) => _run(() => _service.choisirGroupe(groupeId));

  Future<void> deconnecter() => _run(_service.deconnecter);

  Future<void> changerMotDePasse(String motDePasse) =>
      _run(() => _service.changerMotDePasse(motDePasse));

  Future<void> reinitialiserMotDePasse(String email) =>
      _run(() => _service.reinitialiserMotDePasse(email));

  Future<void> renvoyerConfirmation(String email) =>
      _run(() => _service.renvoyerConfirmation(email));

  Future<bool> verifierEmailVerifie() => _run(_service.verifierEmailVerifie);

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
