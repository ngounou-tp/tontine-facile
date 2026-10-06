import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/preuve.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/enums/jour_semaine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/origine_cotisation.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_declaration.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/rules/calcul_montant.dart';
import 'package:tontinefacile/domain/rules/calcul_penalite.dart';
import 'package:tontinefacile/domain/rules/validation_parts.dart';
import 'package:tontinefacile/domain/rules/validation_preuve.dart';
import 'package:tontinefacile/domain/services/calculateur_etat_tour.dart';
import 'package:tontinefacile/domain/services/generateur_echeancier.dart';
import 'package:tontinefacile/domain/services/reorganisateur_tours.dart';
import 'package:tontinefacile/domain/services/traitement_declaration.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';

void main() {
  final nomEntier = Nom(
    id: 'nom-1',
    position: 1,
    libelle: 'Nom 1',
    parts: const [Part(membreId: 'membre-1', fraction: 1)],
  );

  test('valide les fractions et rejette une somme différente de 1', () {
    const validation = ValidationParts();

    expect(
      () => validation.valider(const [
        Part(membreId: 'membre-1', fraction: 0.5),
      ]),
      throwsArgumentError,
    );
    expect(validation.estValide(nomEntier.parts), isTrue);
  });

  test('applique le délai de grâce avant la pénalité', () {
    const calcul = CalculPenalite();
    final echeance = DateTime(2026, 9, 1);

    expect(
      calcul.calculer(
        montantDu: 25000,
        dateEcheance: echeance,
        datePaiement: DateTime(2026, 9, 3),
        delaiGraceJours: 3,
        regle: ReglePenalite.forfaitaire,
        valeurPenalite: 1000,
      ),
      0,
    );
    expect(
      calcul.calculer(
        montantDu: 25000,
        dateEcheance: echeance,
        datePaiement: DateTime(2026, 9, 5),
        delaiGraceJours: 3,
        regle: ReglePenalite.forfaitaire,
        valeurPenalite: 1000,
      ),
      1000,
    );
  });

  test('calcule la quote-part correcte pour un demi-nom', () {
    const calcul = CalculMontant();
    const nomPartage = Nom(
      id: 'nom-partage',
      position: 1,
      libelle: 'Nom partagé',
      parts: [
        Part(membreId: 'membre-1', fraction: 0.5),
        Part(membreId: 'membre-2', fraction: 0.5),
      ],
    );

    expect(
      calcul.calculerMontantPourMembre(
        montantParNom: 25000,
        nom: nomPartage,
        membreId: 'membre-1',
      ),
      12500,
    );
  });

  test('génère un tour par nom et un seul tour en cours', () {
    final tontine = _tontine();
    final tours = const GenerateurEcheancier().generer(
      tontine: tontine,
      noms: [
        Nom(
          id: 'nom-2',
          position: 2,
          libelle: 'Nom 2',
          parts: [Part(membreId: 'membre-2', fraction: 1)],
        ),
        Nom(
          id: 'nom-1',
          position: 1,
          libelle: 'Nom 1',
          parts: [Part(membreId: 'membre-1', fraction: 1)],
        ),
      ],
    );

    expect(tours.map((tour) => tour.nomId), ['nom-1', 'nom-2']);
    expect(tours.where((tour) => tour.statut == StatutTour.enCours), hasLength(1));
    expect(tours[1].datePrevue.isAfter(tours[0].datePrevue), isTrue);
  });

  test('réorganise les tours et conserve un historique motivé', () {
    final tontine = _tontine();
    final tours = const GenerateurEcheancier().generer(
      tontine: tontine,
      noms: [nomEntier, Nom(
        id: 'nom-2',
        position: 2,
        libelle: 'Nom 2',
        parts: [Part(membreId: 'membre-2', fraction: 1)],
      )],
    );

    final resultat = const ReorganisateurTours().reorganiser(
      tontine: tontine,
      tours: tours,
      anciennePosition: 2,
      nouvellePosition: 1,
      motif: 'Accord du groupe',
      auteurUid: 'admin-1',
      dateChangement: DateTime(2026, 9, 9),
    );

    expect(resultat.tours.first.nomId, 'nom-2');
    expect(resultat.tours.map((tour) => tour.position), [1, 2]);
    expect(resultat.changements, isNotEmpty);
    expect(resultat.changements.first.motif, 'Accord du groupe');
  });

  test('valide et conteste une déclaration avec une preuve', () {
    final tontine = _tontine();
    final tour = const GenerateurEcheancier().generer(
      tontine: tontine,
      noms: [nomEntier],
    ).single;
    final declaration = Declaration(
      id: 'declaration-1',
      tourId: tour.id,
      nomId: nomEntier.id,
      membreId: 'membre-1',
      montantDeclare: 25000,
      datePaiement: DateTime(2026, 9, 1),
      preuveId: 'preuve-1',
      statut: StatutDeclaration.enAttente,
      createdAt: DateTime(2026, 9, 1),
    );

    const traitement = TraitementDeclaration();
    final cotisation = traitement.valider(
      declaration: declaration,
      tontine: tontine,
      nom: nomEntier,
      tour: tour,
      adminUid: 'admin-1',
    );
    expect(cotisation.statut, StatutCotisation.validee);
    expect(cotisation.origine, OrigineCotisation.membre);
    expect(
      traitement.validerDeclaration(declaration: declaration).statut,
      StatutDeclaration.validee,
    );

    final contestee = traitement.contester(
      declaration: declaration,
      motif: 'Preuve illisible',
      dateDecision: DateTime(2026, 9, 2),
    );
    expect(contestee.statut, StatutDeclaration.contestee);
    expect(contestee.motifContestation, 'Preuve illisible');
  });

  test('passe un tour à remis lorsque tous les noms sont soldés', () {
    final tontine = _tontine();
    final tour = const GenerateurEcheancier().generer(
      tontine: tontine,
      noms: [nomEntier],
    ).single;
    final cotisation = Cotisation(
      id: 'cotisation-1',
      tourId: tour.id,
      nomId: nomEntier.id,
      membreId: 'membre-1',
      montantDu: 25000,
      montantVerse: 25000,
      datePaiement: DateTime(2026, 9, 1),
      origine: OrigineCotisation.administratrice,
      statut: StatutCotisation.validee,
      auteurUid: 'admin-1',
      penalite: 0,
    );

    final resultat = const CalculateurEtatTour().mettreAJour(
      tontine: tontine,
      tour: tour,
      noms: [nomEntier],
      cotisations: [cotisation],
    );
    expect(resultat.statut, StatutTour.remis);
    expect(resultat.montantRemis, 25000);
  });

  test('rejette une preuve qui atteint la limite de taille', () {
    const validation = ValidationPreuve();
    expect(
      () => validation.valider(Preuve(
        id: 'preuve-1',
        imageEncodee: 'base64',
        tailleOctets: 150000,
        createdAt: DateTime(2026, 9, 1),
      )),
      throwsArgumentError,
    );
  });
}

Tontine _tontine() {
  return Tontine(
    id: 'tontine-1',
    nom: 'Tontine test',
    adminUid: 'admin-1',
    montantParNom: 25000,
    nombreDeNoms: 10,
    datePremiereEcheance: DateTime(2026, 9, 1),
    periodicite: ReglePeriodicite.chaqueSemaine(
      // DateTime.weekday: Tuesday.
      JourSemaine.mardi,
    ),
    reglePenalite: ReglePenalite.aucune,
    delaiGraceJours: 0,
    valeurPenalite: null,
    modeParts: ModeParts.montantFixe,
  );
}