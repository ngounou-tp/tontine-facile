import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/services/inscription_service.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/tontine/application/creation_tontine_controller.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeTontineRepository tontines;
  late FakeGroupesRepository groupes;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService();
    tontines = FakeTontineRepository();
    groupes = FakeGroupesRepository(tontines: tontines, auth: auth);
    container = ProviderContainer(
      overrides: [
        inscriptionServiceProvider.overrideWithValue(
          InscriptionService(authService: auth, groupes: groupes, preferences: FakePreferencesSession()),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test("creerTontine crée la tontine pour le compte connecté, qui en devient le bureau", () async {
    await auth.signUp(email: 'admin@example.com', password: 'secret123');
    final notifier = container.read(creationTontineControllerProvider.notifier);

    final groupeId = await notifier.creerTontine(
      nomCompletAdmin: 'Aïcha Ndiaye',
      tontineSansId: _brouillonTontine(),
    );

    final tontine = tontines.saved[groupeId];
    expect(tontine, isNotNull);
    expect(tontine!.adminUid, auth.currentUser!.uid);
    final adhesion = groupes.adhesionsParUid[auth.currentUser!.uid]!.single;
    expect(adhesion.groupeId, groupeId);
    expect(adhesion.estGestionnaire, isTrue);
    expect(container.read(creationTontineControllerProvider).hasValue, isTrue);
  });

  test("creerTontine échoue si personne n'est connecté", () async {
    final notifier = container.read(creationTontineControllerProvider.notifier);

    await expectLater(
      () => notifier.creerTontine(
        nomCompletAdmin: 'Aïcha Ndiaye',
        tontineSansId: _brouillonTontine(),
      ),
      throwsA(isA<SignInRequiredException>()),
    );
    expect(container.read(creationTontineControllerProvider).hasError, isTrue);
    expect(tontines.saved, isEmpty);
  });
}

Tontine _brouillonTontine() => Tontine(
      id: 'ignore',
      nom: 'Cercle des amies',
      adminUid: 'ignore',
      montantParNom: 25000,
      nombreDeNoms: 10,
      datePremiereEcheance: DateTime(2026, 1, 10),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
    );
