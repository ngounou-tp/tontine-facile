import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/services/inscription_service.dart';
import 'package:tontinefacile/features/auth/application/auth_controller.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/auth/presentation/widgets/auth_form.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeGroupesRepository groupes;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService();
    groupes = FakeGroupesRepository(auth: auth);
    container = ProviderContainer(
      overrides: [
        inscriptionServiceProvider.overrideWithValue(
          InscriptionService(authService: auth, groupes: groupes, preferences: FakePreferencesSession()),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('inscription, connexion puis déconnexion', () async {
    final notifier = container.read(authControllerProvider.notifier);

    expect(
      await notifier.inscrire(email: 'aicha@example.com', password: 'secret123'),
      IssueInscription.connecte,
    );
    await notifier.deconnecter();
    expect(auth.currentUser, isNull);

    final utilisateur = await notifier.connecter(email: 'aicha@example.com', password: 'secret123');
    expect(utilisateur.email, 'aicha@example.com');
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test('un mauvais mot de passe donne un message clair, sans dire si le compte existe', () async {
    final notifier = container.read(authControllerProvider.notifier);
    await notifier.inscrire(email: 'aicha@example.com', password: 'secret123');

    await expectLater(
      () => notifier.connecter(email: 'aicha@example.com', password: 'faux-mot'),
      throwsA(isA<InvalidCredentialsException>()),
    );
    expect(
      messageErreurAuth(container.read(authControllerProvider).error!),
      'Email ou mot de passe incorrect.',
    );
  });

  test("un code d'invitation invalide renvoie un message clair", () async {
    final notifier = container.read(authControllerProvider.notifier);
    await notifier.inscrire(email: 'x@example.com', password: 'secret123');

    await expectLater(
      () => notifier.rejoindreAvecCode('ZZZZZZ'),
      throwsA(isA<InvitationIntrouvableException>()),
    );

    final etat = container.read(authControllerProvider);
    expect(etat.hasError, isTrue);
    expect(messageErreurAuth(etat.error!), "Ce code d'invitation est introuvable.");
  });

  test("annuler la connexion Google n'est pas une erreur", () async {
    final notifier = container.read(authControllerProvider.notifier);

    expect(await notifier.connecterAvecGoogle(), isNull);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test("annuler la connexion Apple n'est pas une erreur", () async {
    final notifier = container.read(authControllerProvider.notifier);

    expect(await notifier.connecterAvecApple(), isNull);
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test("le renvoi de l'email de confirmation vise l'adresse indiquée", () async {
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.renvoyerConfirmation('nouveau@example.com');

    expect(auth.confirmationsRenvoyees, ['nouveau@example.com']);
  });
}
