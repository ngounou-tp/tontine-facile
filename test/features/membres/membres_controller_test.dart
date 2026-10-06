import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/membres/application/membres_controller.dart';

import '../../support/fakes.dart';

void main() {
  late FakeTontineRepository tontines;
  late ProviderContainer container;

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = Tontine(
      id: 't-1',
      nom: 'Cercle des amies',
      adminUid: 'admin',
      montantParNom: 25000,
      nombreDeNoms: 10,
      datePremiereEcheance: DateTime(2026, 1, 10),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
    );
    container = ProviderContainer(
      overrides: [tontineRepositoryProvider.overrideWithValue(tontines)],
    );
  });

  tearDown(() => container.dispose());

  test('inviterMembre crée un membre sans compte et son code', () async {
    final notifier = container.read(membresControllerProvider.notifier);

    final invitation = await notifier.inviterMembre(
      tontineId: 't-1',
      nomComplet: 'Marie Ngo',
      whatsapp: '+237690000000',
    );

    final membre = tontines.membres[invitation.membreId]!;
    expect(membre.nomComplet, 'Marie Ngo');
    expect(membre.uid, isNull);
    expect(membre.codeInvitation, invitation.code);
  });

  test(
    'modifierMembre met à jour les coordonnées en conservant id/uid/actif',
    () async {
      tontines.membres['m-1'] = const Membre(
        id: 'm-1',
        nomComplet: 'Ancien nom',
        uid: 'uid-1',
      );
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.modifierMembre(
        tontineId: 't-1',
        membre: tontines.membres['m-1']!,
        nomComplet: 'Nouveau nom',
        email: 'nouveau@example.com',
      );

      final maj = tontines.membres['m-1']!;
      expect(maj.nomComplet, 'Nouveau nom');
      expect(maj.email, 'nouveau@example.com');
      expect(maj.uid, 'uid-1');
      expect(maj.actif, isTrue);
    },
  );

  test('desactiverMembre puis reactiverMembre basculent le statut actif',
      () async {
    tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Marie');
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.desactiverMembre(
      tontineId: 't-1',
      membre: tontines.membres['m-1']!,
    );
    expect(tontines.membres['m-1']!.actif, isFalse);

    await notifier.reactiverMembre(
      tontineId: 't-1',
      membre: tontines.membres['m-1']!,
    );
    expect(tontines.membres['m-1']!.actif, isTrue);
  });

  test('creerNom valide les parts puis les enregistre', () async {
    final notifier = container.read(membresControllerProvider.notifier);

    final nom = await notifier.creerNom(
      tontineId: 't-1',
      position: 1,
      parts: const [Part(membreId: 'm-1', fraction: 1)],
    );

    expect(tontines.noms[nom.id]?.libelle, 'Nom 1');
    expect(tontines.noms[nom.id]?.parts.single.membreId, 'm-1');
  });

  test("creerNom rejette des parts dont la somme n'est pas 1", () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await expectLater(
      () => notifier.creerNom(
        tontineId: 't-1',
        position: 1,
        parts: const [Part(membreId: 'm-1', fraction: 0.5)],
      ),
      throwsArgumentError,
    );
    expect(tontines.noms, isEmpty);
  });

  test("assignerParts réassigne les détenteurs d'un nom existant", () async {
    tontines.noms['n-1'] = const Nom(
      id: 'n-1',
      position: 1,
      libelle: 'Nom 1',
      parts: [Part(membreId: 'm-1', fraction: 1)],
    );
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.assignerParts(
      tontineId: 't-1',
      nom: tontines.noms['n-1']!,
      parts: const [
        Part(membreId: 'm-2', fraction: 0.5),
        Part(membreId: 'm-3', fraction: 0.5),
      ],
    );

    final parts = tontines.noms['n-1']!.parts;
    expect(parts.map((p) => p.membreId), containsAll(['m-2', 'm-3']));
  });

  test("assignerParts rejette des parts invalides sans modifier le nom",
      () async {
    const nomInitial = Nom(
      id: 'n-1',
      position: 1,
      libelle: 'Nom 1',
      parts: [Part(membreId: 'm-1', fraction: 1)],
    );
    tontines.noms['n-1'] = nomInitial;
    final notifier = container.read(membresControllerProvider.notifier);

    await expectLater(
      () => notifier.assignerParts(
        tontineId: 't-1',
        nom: nomInitial,
        parts: const [], // liste vide : ValidationParts doit refuser.
      ),
      throwsArgumentError,
    );
    expect(tontines.noms['n-1'], nomInitial);
  });

  test('inviterMembreAvecNoms(1) crée un nom entier lui appartenant seul',
      () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.inviterMembreAvecNoms(
      tontineId: 't-1',
      nomComplet: 'Rose Domche',
      whatsapp: '+237600000000',
      nombreDeNoms: 1,
    );

    expect(tontines.noms, hasLength(1));
    final nom = tontines.noms.values.single;
    expect(nom.libelle, 'Nom 1');
    expect(nom.parts.single.fraction, 1);
  });

  test('inviterMembreAvecNoms(0.5) ouvre un nom en attente d\'un second '
      'détenteur', () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.inviterMembreAvecNoms(
      tontineId: 't-1',
      nomComplet: 'Rose Domche',
      whatsapp: '+237600000000',
      nombreDeNoms: 0.5,
    );

    expect(tontines.noms, hasLength(1));
    final nom = tontines.noms.values.single;
    expect(nom.parts.single.fraction, 0.5);
  });

  test(
    'inviterMembreAvecNoms(0.5) complète un nom déjà à moitié attribué '
    'plutôt que d\'en ouvrir un nouveau',
    () async {
      final notifier = container.read(membresControllerProvider.notifier);
      await notifier.inviterMembreAvecNoms(
        tontineId: 't-1',
        nomComplet: 'Rose Domche',
        whatsapp: '+237600000000',
        nombreDeNoms: 0.5,
      );

      await notifier.inviterMembreAvecNoms(
        tontineId: 't-1',
        nomComplet: 'Alice Pouth',
        whatsapp: '+237611111111',
        nombreDeNoms: 0.5,
      );

      expect(tontines.noms, hasLength(1));
      final nom = tontines.noms.values.single;
      expect(nom.parts, hasLength(2));
      expect(
        nom.parts.fold<double>(0, (total, part) => total + part.fraction),
        1,
      );
    },
  );

  test('inviterMembreAvecNoms(1.5) crée un nom entier et un nom en attente',
      () async {
    final notifier = container.read(membresControllerProvider.notifier);

    await notifier.inviterMembreAvecNoms(
      tontineId: 't-1',
      nomComplet: 'Rose Domche',
      whatsapp: '+237600000000',
      nombreDeNoms: 1.5,
    );

    expect(tontines.noms, hasLength(2));
    final fractions = tontines.noms.values.map((n) => n.parts.single.fraction).toList()
      ..sort();
    expect(fractions, [0.5, 1.0]);
  });

  test(
    'attribuerNomsSupplementaires ajoute des noms à un membre déjà enregistré',
    () async {
      tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche');
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.attribuerNomsSupplementaires(
        tontineId: 't-1',
        membreId: 'm-1',
        nombreDeNoms: 2,
      );

      expect(tontines.noms, hasLength(2));
      expect(
        tontines.noms.values.every((n) => n.parts.single.membreId == 'm-1'),
        isTrue,
      );
    },
  );

  test(
    'attribuerNomsSupplementaires refuse de dépasser le nombre de noms de '
    'la tontine',
    () async {
      // La tontine du setUp() prévoit nombreDeNoms: 10.
      tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche');
      final notifier = container.read(membresControllerProvider.notifier);

      await expectLater(
        () => notifier.attribuerNomsSupplementaires(
          tontineId: 't-1',
          membreId: 'm-1',
          nombreDeNoms: 11,
        ),
        throwsA(isA<NamesQuotaExceededException>()),
      );
      expect(tontines.noms, isEmpty);
    },
  );

  test(
    'attribuerNomsSupplementaires accepte exactement le quota restant',
    () async {
      tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche');
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.attribuerNomsSupplementaires(
        tontineId: 't-1',
        membreId: 'm-1',
        nombreDeNoms: 10,
      );

      expect(tontines.noms, hasLength(10));
    },
  );

  test(
    'modifierMembre et desactiverMembre conservent le codeInvitation existant',
    () async {
      tontines.membres['m-1'] = const Membre(
        id: 'm-1',
        nomComplet: 'Rose Domche',
        codeInvitation: 'ABC123',
      );
      final notifier = container.read(membresControllerProvider.notifier);

      await notifier.modifierMembre(
        tontineId: 't-1',
        membre: tontines.membres['m-1']!,
        nomComplet: 'Rose D.',
      );
      expect(tontines.membres['m-1']!.codeInvitation, 'ABC123');

      await notifier.desactiverMembre(tontineId: 't-1', membre: tontines.membres['m-1']!);
      expect(tontines.membres['m-1']!.codeInvitation, 'ABC123');
      expect(tontines.membres['m-1']!.actif, isFalse);
    },
  );
}
