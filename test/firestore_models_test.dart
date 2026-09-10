import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/data/models/changement_model.dart';
import 'package:tontinefacile/data/models/cotisation_model.dart';
import 'package:tontinefacile/data/models/declaration_model.dart';
import 'package:tontinefacile/data/models/membre_model.dart';
import 'package:tontinefacile/data/models/nom_model.dart';
import 'package:tontinefacile/data/models/part_model.dart';
import 'package:tontinefacile/data/models/preuve_model.dart';
import 'package:tontinefacile/data/models/tontine_model.dart';
import 'package:tontinefacile/data/models/tour_model.dart';
import 'package:tontinefacile/domain/entities/changement.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/preuve.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/jour_semaine.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/origine_cotisation.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_declaration.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';

void main() {
  final date = DateTime(2026, 9, 9, 10, 30);

  test('sérialise une tontine avec sa périodicité et ses enums', () {
    final entity = Tontine(
      id: 'tontine-1',
      nom: 'Tontine test',
      adminUid: 'admin-1',
      montantParNom: 25000,
      datePremiereEcheance: date,
      periodicite: ReglePeriodicite.chaqueSemaine(JourSemaine.mercredi),
      reglePenalite: ReglePenalite.proportionnelle,
      delaiGraceJours: 3,
      valeurPenalite: 5,
      modeParts: ModeParts.montantFixe,
      codeInvitation: 'ABC123',
    );
    final model = TontineModel.fromEntity(entity);
    final data = model.toFirestore();
    final restored = TontineModel.fromFirestore(data, id: entity.id).toEntity();

    expect(data['datePremiereEcheance'], isA<Timestamp>());
    expect(data, isNot(contains('id')));
    expect(restored.id, entity.id);
    expect(restored.nom, entity.nom);
    expect(restored.periodicite.toJson(), entity.periodicite.toJson());
    expect(restored.modeParts, entity.modeParts);
  });

  test('sérialise les parts imbriquées dans un nom', () {
    const entity = Nom(
      id: 'nom-1',
      position: 1,
      libelle: 'Nom partagé',
      parts: [
        Part(membreId: 'membre-1', fraction: 0.5),
        Part(membreId: 'membre-2', fraction: 0.5),
      ],
    );
    final model = NomModel.fromEntity(entity);
    final restored = NomModel.fromFirestore(model.toFirestore(), id: entity.id).toEntity();

    expect(restored.id, entity.id);
    expect(restored.parts.map((part) => part.fraction), [0.5, 0.5]);
    expect(PartModel.fromEntity(entity.parts.first).toEntity().membreId, 'membre-1');
  });

  test('round-trip des documents membres et opérationnels', () {
    final membre = MembreModel.fromEntity(const Membre(
      id: 'membre-1',
      nomComplet: 'Marie Ngo',
      whatsapp: '+237600000000',
    ));
    expect(MembreModel.fromFirestore(membre.toFirestore(), id: membre.id).toEntity().nomComplet, 'Marie Ngo');

    final tour = TourModel.fromEntity(Tour(
      id: 'tour-1',
      nomId: 'nom-1',
      position: 1,
      datePrevue: date,
      statut: StatutTour.enCours,
    ));
    expect(TourModel.fromFirestore(tour.toFirestore(), id: tour.id).toEntity().statut, StatutTour.enCours);

    final preuve = PreuveModel.fromEntity(Preuve(
      id: 'preuve-1',
      imageEncodee: 'base64',
      tailleOctets: 120000,
      createdAt: date,
    ));
    expect(PreuveModel.fromFirestore(preuve.toFirestore(), id: preuve.id).toEntity().tailleOctets, 120000);
  });

  test('round-trip des cotisations, déclarations et historique', () {
    final cotisation = CotisationModel.fromEntity(Cotisation(
      id: 'cotisation-1',
      tourId: 'tour-1',
      nomId: 'nom-1',
      membreId: 'membre-1',
      montantDu: 25000,
      montantVerse: 25000,
      datePaiement: date,
      origine: OrigineCotisation.membre,
      statut: StatutCotisation.validee,
      auteurUid: 'admin-1',
      penalite: 0,
      preuveId: 'preuve-1',
    ));
    expect(CotisationModel.fromFirestore(cotisation.toFirestore(), id: cotisation.id).toEntity().origine, OrigineCotisation.membre);

    final declaration = DeclarationModel.fromEntity(Declaration(
      id: 'declaration-1',
      tourId: 'tour-1',
      nomId: 'nom-1',
      membreId: 'membre-1',
      montantDeclare: 25000,
      datePaiement: date,
      preuveId: 'preuve-1',
      statut: StatutDeclaration.enAttente,
      createdAt: date,
    ));
    expect(DeclarationModel.fromFirestore(declaration.toFirestore(), id: declaration.id).toEntity().statut, StatutDeclaration.enAttente);

    final changement = ChangementModel.fromEntity(Changement(
      id: 'changement-1',
      tourId: 'tour-1',
      anciennePosition: 2,
      nouvellePosition: 1,
      motif: 'Accord du groupe',
      auteurUid: 'admin-1',
      createdAt: date,
    ));
    expect(ChangementModel.fromFirestore(changement.toFirestore(), id: changement.id).toEntity().motif, 'Accord du groupe');
  });

  test('rejette les données Firestore invalides', () {
    expect(
      () => MembreModel.fromFirestore({'nomComplet': 12}, id: 'membre-1'),
      throwsFormatException,
    );
    expect(
      () => TourModel.fromFirestore({
        'nomId': 'nom-1',
        'position': 1,
        'datePrevue': 'date invalide',
        'statut': 'enCours',
      }, id: 'tour-1'),
      throwsFormatException,
    );
  });
}
