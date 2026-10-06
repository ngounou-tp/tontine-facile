import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/profil.dart';
import 'package:tontinefacile/domain/entities/session.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/origine_cotisation.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_declaration.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';
import 'package:tontinefacile/features/auth/application/auth_providers.dart';
import 'package:tontinefacile/features/cotisations/application/cotisations_providers.dart';
import 'package:tontinefacile/features/echeancier/application/echeancier_providers.dart';
import 'package:tontinefacile/features/espace_membre/application/espace_membre_providers.dart';
import 'package:tontinefacile/features/membres/application/membres_providers.dart';
import 'package:tontinefacile/features/tontine/application/tontine_providers.dart';

import '../../support/fakes.dart' show FakeTontineRepository;

Tontine _tontine() => Tontine(
      id: 't-1',
      nom: 'Cercle des amies',
      adminUid: 'admin-uid',
      montantParNom: 25000,
      nombreDeNoms: 3,
      datePremiereEcheance: DateTime(2026, 1, 10),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.aucune,
      delaiGraceJours: 0,
      valeurPenalite: null,
      modeParts: ModeParts.montantFixe,
    );

void main() {
  late FakeTontineRepository tontines;
  late ProviderContainer container;

  setUp(() {
    tontines = FakeTontineRepository();
    tontines.saved['t-1'] = _tontine();
    tontines.membres['m-1'] = const Membre(id: 'm-1', nomComplet: 'Rose Domche', uid: 'uid-1');
    tontines.membres['m-2'] = const Membre(id: 'm-2', nomComplet: 'Alice Pouth', uid: 'uid-2');
    tontines.noms['n-1'] = const Nom(id: 'n-1', position: 1, libelle: 'Nom 1', parts: [Part(membreId: 'm-1', fraction: 1)]);
    tontines.noms['n-2'] = const Nom(id: 'n-2', position: 2, libelle: 'Nom 2', parts: [Part(membreId: 'm-2', fraction: 1)]);
    tontines.noms['n-3'] = const Nom(id: 'n-3', position: 3, libelle: 'Nom 3', parts: [Part(membreId: 'm-1', fraction: 1)]);
    tontines.tours['tour-1'] = Tour(id: 'tour-1', nomId: 'n-2', position: 1, datePrevue: DateTime(2026, 1, 10), statut: StatutTour.enCours);
    tontines.tours['tour-2'] = Tour(id: 'tour-2', nomId: 'n-1', position: 2, datePrevue: DateTime(2026, 1, 17), statut: StatutTour.aVenir);
    tontines.tours['tour-3'] = Tour(id: 'tour-3', nomId: 'n-3', position: 3, datePrevue: DateTime(2026, 1, 24), statut: StatutTour.aVenir);

    container = ProviderContainer(
      overrides: [
        tontineRepositoryProvider.overrideWithValue(tontines),
        sessionProvider.overrideWith(
          (ref) => Stream.value(const Session(
            utilisateur: AppUser(uid: 'uid-1'),
            profil: Profil(uid: 'uid-1', tontineId: 't-1', membreId: 'm-1'),
          )),
        ),
      ],
    );
    // Maintient un abonnement permanent à sessionProvider, comme le ferait
    // un widget avec ref.watch : sans lui, un simple .read(...future) laisse
    // le StreamProvider sans écouteur au moment de container.dispose(),
    // ce qui le bloque indéfiniment dans son état de chargement.
    // Même chose pour les providers en aval : chacun doit garder un
    // écouteur permanent (sinon la même impasse au dispose) et être attendu
    // avant lecture (chacun dérive du précédent, donc résout sur un tick
    // suivant, pas le même).
    container.listen(tontineProvider, (_, _) {});
    container.listen(membresProvider, (_, _) {});
    container.listen(nomsProvider, (_, _) {});
    container.listen(toursProvider, (_, _) {});
    container.listen(cotisationsProvider, (_, _) {});
    container.listen(declarationsProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<void> attendreTout() async {
    await container.read(sessionProvider.future);
    await container.read(tontineProvider.future);
    await container.read(membresProvider.future);
    await container.read(nomsProvider.future);
    await container.read(toursProvider.future);
    await container.read(cotisationsProvider.future);
    await container.read(declarationsProvider.future);
  }

  test('membreCourantProvider résout la fiche du membre connecté', () async {
    await attendreTout();
    expect(container.read(membreCourantProvider)?.nomComplet, 'Rose Domche');
  });

  test('mesNomsProvider ne renvoie que les noms détenus par le membre connecté', () async {
    await attendreTout();
    final mesNoms = container.read(mesNomsProvider);
    expect(mesNoms.map((e) => e.nom.id).toSet(), {'n-1', 'n-3'});
  });

  test(
    'prochainTourMembreProvider trouve le prochain tour parmi les noms du '
    'membre, pas le tour en cours général',
    () async {
      await attendreTout();
      // Le tour en cours (tour-1) concerne le nom n-2 (Alice), pas Rose.
      // Le prochain tour DE ROSE est tour-2 (nom n-1, position 2).
      final prochain = container.read(prochainTourMembreProvider);
      expect(prochain?.id, 'tour-2');
    },
  );

  test(
    'mesSituationsTourActuelProvider calcule montant dû/versé et éligibilité '
    'à déclarer pour le tour en cours',
    () async {
      await attendreTout();
      tontines.cotisations['c-1'] = Cotisation(
        id: 'c-1',
        tourId: 'tour-1',
        nomId: 'n-1',
        membreId: 'm-1',
        montantDu: 25000,
        montantVerse: 10000,
        datePaiement: DateTime(2026, 1, 10),
        origine: OrigineCotisation.membre,
        statut: StatutCotisation.validee,
        auteurUid: 'admin-uid',
        penalite: 0,
      );
      // Force re-lecture après mutation directe du fake.
      container.invalidate(cotisationsProvider);
      await container.read(cotisationsProvider.future);
      final situations = container.read(mesSituationsTourActuelProvider);

      final n1 = situations.firstWhere((s) => s.nom.id == 'n-1');
      expect(n1.montantVerse, 10000);
      expect(n1.montantDu, 25000);
      expect(n1.peutDeclarer, isTrue);

      final n3 = situations.firstWhere((s) => s.nom.id == 'n-3');
      expect(n3.montantVerse, 0);
      expect(n3.peutDeclarer, isTrue);
    },
  );

  test(
    'mesSituationsTourActuelProvider marque un nom non déclarable si une '
    'déclaration est déjà en attente',
    () async {
      await attendreTout();
      tontines.declarations['d-1'] = Declaration(
        id: 'd-1',
        tourId: 'tour-1',
        nomId: 'n-1',
        membreId: 'm-1',
        montantDeclare: 25000,
        datePaiement: DateTime(2026, 1, 10),
        preuveId: 'preuve-1',
        statut: StatutDeclaration.enAttente,
        createdAt: DateTime(2026, 1, 10),
      );
      container.invalidate(declarationsProvider);
      await container.read(declarationsProvider.future);
      final situations = container.read(mesSituationsTourActuelProvider);

      final n1 = situations.firstWhere((s) => s.nom.id == 'n-1');
      expect(n1.declarationEnAttente, isTrue);
      expect(n1.peutDeclarer, isFalse);
    },
  );
}
