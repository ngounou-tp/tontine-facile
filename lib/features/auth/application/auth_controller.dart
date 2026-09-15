import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/inscription_service.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/entities/tontine.dart';
import 'auth_providers.dart';

/// État partagé des actions d'authentification lancées par les formulaires.
///
/// Les pages peuvent écouter [authControllerProvider] pour désactiver leur
/// bouton pendant une requête et afficher une erreur métier avec
/// `state.whenOrNull(error: ...)`.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  InscriptionService get _service => ref.read(inscriptionServiceProvider);

  @override
  Future<void> build() async {}

  Future<Session> connecter({
    required String email,
    required String password,
  }) => _run(() => _service.connecter(email: email, password: password));

  Future<Session> inscrireAdmin({
    required String email,
    required String password,
    required String nomCompletAdmin,
    required Tontine tontineSansId,
  }) => _run(
    () => _service.inscrireAdmin(
      email: email,
      password: password,
      nomCompletAdmin: nomCompletAdmin,
      tontineSansId: tontineSansId,
    ),
  );

  Future<Session> inscrireMembre({
    required String email,
    required String password,
    required String codeInvitation,
  }) => _run(
    () => _service.inscrireMembre(
      email: email,
      password: password,
      codeInvitation: codeInvitation,
    ),
  );

  Future<Session> creerCompteSansTontine({
    required String email,
    required String password,
  }) => _run(
    () => _service.creerCompteSansTontine(email: email, password: password),
  );

  Future<Session> rejoindreAvecCode(String codeInvitation) =>
      _run(() => _service.rejoindreAvecCode(codeInvitation));

  /// Renvoie `null` si l'utilisateur annule la sélection de compte Google
  /// (ce n'est pas une erreur : ne rien afficher dans ce cas).
  Future<Session?> connecterAvecGoogle() => _run(_service.connecterAvecGoogle);

  Future<void> deconnecter() => _runVoid(_service.deconnecter);

  Future<void> reinitialiserMotDePasse(String email) =>
      _runVoid(() => _service.reinitialiserMotDePasse(email));

  Future<void> renvoyerEmailVerification() =>
      _runVoid(_service.renvoyerEmailVerification);

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
