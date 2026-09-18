import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/data/repositories/tontine_repository.dart';
import 'package:tontinefacile/domain/entities/changement.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/preuve.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/tontine/application/modification_tontine_controller.dart';

void main() {
  late FakeTontineRepository tontines;
  late ProviderContainer container;

  final tontineInitiale = Tontine(
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
    codeInvitation: 'ABCDEF',
  );

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = tontineInitiale;
    container = ProviderContainer(
      overrides: [tontineRepositoryProvider.overrideWithValue(tontines)],
    );
  });

  tearDown(() => container.dispose());

  test('modifierTontine enregistre les changements valides', () async {
    final notifier = container.read(modificationTontineControllerProvider.notifier);
    final misAJour = Tontine(
      id: tontineInitiale.id,
      nom: 'Nouveau nom',
      adminUid: tontineInitiale.adminUid,
      montantParNom: 30000,
      nombreDeNoms: 12,
      datePremiereEcheance: tontineInitiale.datePremiereEcheance,
      periodicite: tontineInitiale.periodicite,
      reglePenalite: tontineInitiale.reglePenalite,
      delaiGraceJours: tontineInitiale.delaiGraceJours,
      valeurPenalite: tontineInitiale.valeurPenalite,
      modeParts: tontineInitiale.modeParts,
      codeInvitation: tontineInitiale.codeInvitation,
    );

    await notifier.modifierTontine(misAJour);

    expect(tontines.saved['t-1']!.nom, 'Nouveau nom');
    expect(tontines.saved['t-1']!.montantParNom, 30000);
    expect(tontines.saved['t-1']!.nombreDeNoms, 12);
    expect(container.read(modificationTontineControllerProvider).hasValue, isTrue);
  });

  test('modifierTontine rejette une tontine invalide sans écrire', () async {
    final notifier = container.read(modificationTontineControllerProvider.notifier);
    final invalide = Tontine(
      id: tontineInitiale.id,
      nom: 'x',
      adminUid: tontineInitiale.adminUid,
      montantParNom: tontineInitiale.montantParNom,
      nombreDeNoms: tontineInitiale.nombreDeNoms,
      datePremiereEcheance: tontineInitiale.datePremiereEcheance,
      periodicite: tontineInitiale.periodicite,
      reglePenalite: tontineInitiale.reglePenalite,
      delaiGraceJours: tontineInitiale.delaiGraceJours,
      valeurPenalite: tontineInitiale.valeurPenalite,
      modeParts: tontineInitiale.modeParts,
      codeInvitation: tontineInitiale.codeInvitation,
    );

    await expectLater(
      () => notifier.modifierTontine(invalide),
      throwsArgumentError,
    );
    expect(tontines.saved['t-1']!.nom, 'Cercle des amies');
  });
}

class FakeTontineRepository implements TontineRepository {
  final Map<String, Tontine> saved = {};
  final Map<String, Membre> membres = {};
  final Map<String, Nom> noms = {};
  var _nextId = 0;

  @override
  String nouvelIdTontine() => 'tontine-${_nextId++}';
  @override
  Future<List<Tontine>> getTontines() async => saved.values.toList();
  @override
  Future<Tontine?> getTontine(String tontineId) async => saved[tontineId];
  @override
  Future<void> saveTontine(Tontine tontine) async => saved[tontine.id] = tontine;
  @override
  Future<List<Membre>> getMembres(String tontineId) async => membres.values.toList();
  @override
  Future<void> saveMembre(String tontineId, Membre membre) async => membres[membre.id] = membre;

  @override
  Future<Membre> creerMembrePlaceholder(
    String tontineId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) async {
    final membre = Membre(id: 'membre-${_nextId++}', nomComplet: nomComplet, email: email, whatsapp: whatsapp);
    membres[membre.id] = membre;
    return membre;
  }

  @override
  Future<void> claimMembre({
    required String tontineId,
    required String membreId,
    required String uid,
    required String codeInvitation,
  }) async {}

  @override
  Future<List<Nom>> getNoms(String tontineId) async => noms.values.toList();
  @override
  String nouvelIdNom(String tontineId) => 'nom-${_nextId++}';
  @override
  Future<void> saveNom(String tontineId, Nom nom) async => noms[nom.id] = nom;
  @override
  Stream<Tontine?> watchTontine(String tontineId) => Stream.value(saved[tontineId]);
  @override
  Stream<List<Membre>> watchMembres(String tontineId) => Stream.value(membres.values.toList());
  @override
  Stream<List<Nom>> watchNoms(String tontineId) => Stream.value(noms.values.toList());
  @override
  Stream<List<Tour>> watchTours(String tontineId) => Stream.value(const []);
  @override
  Future<List<Tour>> getTours(String tontineId) async => const [];
  @override
  Future<void> saveTour(String tontineId, Tour tour) async {}
  @override
  Future<List<Cotisation>> getCotisations(String tontineId) async => const [];
  @override
  Future<void> saveCotisation(String tontineId, Cotisation cotisation) async {}
  @override
  String nouvelIdCotisation(String tontineId) => 'cotisation-${_nextId++}';
  @override
  Stream<List<Cotisation>> watchCotisations(String tontineId) => Stream.value(const []);
  @override
  Future<List<Declaration>> getDeclarations(String tontineId) async => const [];
  @override
  Future<void> saveDeclaration(String tontineId, Declaration declaration) async {}
  @override
  Future<List<Preuve>> getPreuves(String tontineId) async => const [];
  @override
  Future<void> savePreuve(String tontineId, Preuve preuve) async {}
  @override
  String nouvelIdDeclaration(String tontineId) => 'declaration-${_nextId++}';
  @override
  Stream<List<Declaration>> watchDeclarations(String tontineId) => Stream.value(const []);
  @override
  String nouvelIdPreuve(String tontineId) => 'preuve-${_nextId++}';
  @override
  Future<List<Changement>> getChangements(String tontineId) async => const [];
  @override
  Future<void> saveChangement(String tontineId, Changement changement) async {}
  @override
  Stream<List<Changement>> watchChangements(String tontineId) => Stream.value(const []);
}
