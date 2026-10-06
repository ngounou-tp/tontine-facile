// Tests d'intégration : les repositories Supabase du client, contre une
// vraie API PostgREST et la base migrée (RLS, fonctions SQL, jointures).
// Lancés par `supabase/tests/run_api_local.sh` ; ignorés sinon.
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestClient;
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/repositories/supabase_groupes_repository.dart';
import 'package:tontinefacile/data/repositories/supabase_tontine_repository.dart';
import 'package:tontinefacile/data/supabase/stockage_preuves.dart';
import 'package:tontinefacile/data/supabase/table_changes.dart';
import 'package:tontinefacile/domain/entities/changement.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/domain/entities/preuve.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/origine_cotisation.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/role_membre.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_declaration.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/services/generateur_echeancier.dart';
import 'package:tontinefacile/domain/services/reorganisateur_tours.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';

final _url = Platform.environment['POSTGREST_URL'];
final _secret = Platform.environment['POSTGREST_JWT_SECRET'];

const _adele = '11111111-1111-1111-1111-111111111111';
const _bruno = '22222222-2222-2222-2222-222222222222';
const _chantal = '33333333-3333-3333-3333-333333333333';
const _dora = '44444444-4444-4444-4444-444444444444';

String _b64(List<int> octets) => base64Url.encode(octets).replaceAll('=', '');

/// Jeton signé comme ceux de Supabase Auth.
String _jwt(String uid) {
  final entete = _b64(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
  final contenu = _b64(utf8.encode(jsonEncode({
    'sub': uid,
    'role': 'authenticated',
    'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
  })));
  final signature = Hmac(sha256, utf8.encode(_secret!)).convert(utf8.encode('$entete.$contenu'));
  return '$entete.$contenu.${_b64(signature.bytes)}';
}

PostgrestClient _db(String uid) => PostgrestClient(_url!, headers: {'Authorization': 'Bearer ${_jwt(uid)}'});

class _StockageMemoire implements StockagePreuves {
  final fichiers = <String, Uint8List>{};
  @override
  Future<void> deposer(String chemin, Uint8List octets) async => fichiers[chemin] = octets;
  @override
  Future<Uint8List> telecharger(String chemin) async => fichiers[chemin]!;
}

({SupabaseTontineRepository tontines, SupabaseGroupesRepository groupes}) _comme(
  String uid,
  StockagePreuves stockage,
) =>
    (
      tontines: SupabaseTontineRepository(db: _db(uid), changes: const NoTableChanges(), stockage: stockage),
      groupes: SupabaseGroupesRepository(db: _db(uid), changes: const NoTableChanges()),
    );

Tontine _brouillon(String nom) => Tontine(
      id: 'ignore',
      nom: nom,
      adminUid: 'ignore',
      montantParNom: 25000,
      nombreDeNoms: 2,
      datePremiereEcheance: DateTime(2026, 11, 7),
      periodicite: ReglePeriodicite.tousLesNJours(7),
      reglePenalite: ReglePenalite.forfaitaire,
      delaiGraceJours: 2,
      valeurPenalite: 1000,
      modeParts: ModeParts.montantFixe,
    );

void main() {
  final ignore = _url == null || _secret == null ? 'lancé par supabase/tests/run_api_local.sh' : null;
  final stockage = _StockageMemoire();

  test('cycle complet : création, invitation, adhésion, noms, échéancier, déclaration, validation', () async {
    final adele = _comme(_adele, stockage);
    final bruno = _comme(_bruno, stockage);
    final chantal = _comme(_chantal, stockage);

    // ---- création et réglages
    final groupeId = await adele.groupes.creerTontine(
      tontine: _brouillon('Njangi ${DateTime.now().microsecondsSinceEpoch}'),
      nomCompletAdmin: 'Adèle Tchoumi',
    );
    final tontine = (await adele.tontines.getTontine(groupeId))!;
    expect(tontine.montantParNom, 25000);
    expect(tontine.periodicite.toJson(), {'type': 'tousLesNJours', 'jours': 7});
    expect(tontine.datePremiereEcheance, DateTime(2026, 11, 7));
    expect(tontine.valeurPenalite, 1000);

    final adhesionsAdele = await adele.groupes.watchAdhesions(_adele).first;
    final adhesion = adhesionsAdele.singleWhere((a) => a.groupeId == groupeId);
    expect(adhesion.roles, {RoleMembre.proprietaire, RoleMembre.tresorier});
    expect(adhesion.estGestionnaire, isTrue);

    // ---- invitation et adhésion
    final invitation = await adele.tontines.inviterMembre(groupeId, nomComplet: 'Bruno Ekotto', whatsapp: '+237690000001');
    final apercu = await bruno.groupes.apercuInvitation(invitation.code.toLowerCase());
    expect(apercu?.nomGroupe, tontine.nom);
    expect(apercu?.dejaUtilisee, isFalse);

    final adhesionBruno = await bruno.groupes.rejoindre(invitation.code);
    expect(adhesionBruno.groupeId, groupeId);
    expect(adhesionBruno.membreId, invitation.membreId);
    await expectLater(chantal.groupes.rejoindre(invitation.code), throwsA(isA<InvitationDejaUtiliseeException>()));
    await expectLater(chantal.groupes.rejoindre('ZZZZZZ'), throwsA(isA<InvitationIntrouvableException>()));

    final membres = await bruno.tontines.getMembres(groupeId);
    expect(membres.map((m) => m.nomComplet), containsAll(['Adèle Tchoumi', 'Bruno Ekotto']));
    final membreAdele = membres.singleWhere((m) => m.nomComplet == 'Adèle Tchoumi');
    final membreBruno = membres.singleWhere((m) => m.id == invitation.membreId);
    expect(membreBruno.uid, _bruno);
    expect(membreBruno.codeInvitation, invitation.code);

    // Un membre ne gère pas le groupe ; une étrangère ne voit rien.
    await expectLater(
      bruno.tontines.inviterMembre(groupeId, nomComplet: 'Intrus', email: 'x@y.z'),
      throwsA(isA<ActionNonAutoriseeException>()),
    );
    expect(await chantal.tontines.getTontine(groupeId), isNull);
    expect(await chantal.tontines.getMembres(groupeId), isEmpty);

    // ---- noms et parts (dont un partagé en demies)
    final nom1 = Nom(
      id: adele.tontines.nouvelIdNom(groupeId),
      position: 1,
      libelle: 'Nom 1',
      parts: [Part(membreId: membreBruno.id, fraction: 1)],
    );
    final nom2 = Nom(
      id: adele.tontines.nouvelIdNom(groupeId),
      position: 2,
      libelle: 'Nom 2',
      parts: [
        Part(membreId: membreAdele.id, fraction: 0.5),
        Part(membreId: membreBruno.id, fraction: 0.5),
      ],
    );
    await adele.tontines.saveNom(groupeId, nom1);
    await adele.tontines.saveNom(groupeId, nom2);
    final noms = await bruno.tontines.getNoms(groupeId);
    expect(noms.map((n) => n.position), [1, 2]);
    expect(noms[1].parts.map((p) => p.fraction), [0.5, 0.5]);
    await expectLater(
      adele.tontines.saveNom(
        groupeId,
        Nom(id: adele.tontines.nouvelIdNom(groupeId), position: 3, libelle: 'Nom 3', parts: [Part(membreId: membreAdele.id, fraction: 1)]),
      ),
      throwsA(isA<NamesQuotaExceededException>()),
    );
    await expectLater(
      bruno.tontines.saveNom(groupeId, nom1),
      throwsA(isA<ActionNonAutoriseeException>()),
    );

    // ---- échéancier (génération en une requête)
    final tours = const GenerateurEcheancier().generer(
      tontine: tontine,
      noms: noms,
      nouvelId: (_) => adele.tontines.nouvelIdTour(groupeId),
    );
    await adele.tontines.saveTours(groupeId, tours);
    final toursLus = await bruno.tontines.getTours(groupeId);
    expect(toursLus.map((t) => t.statut), [StatutTour.enCours, StatutTour.aVenir]);
    expect(toursLus[1].datePrevue, DateTime(2026, 11, 14));

    // ---- déclaration de Bruno, avec preuve
    final preuve = Preuve(
      id: bruno.tontines.nouvelIdPreuve(groupeId),
      imageEncodee: base64Encode(List<int>.filled(2048, 7)),
      tailleOctets: 2048,
      createdAt: DateTime.now(),
    );
    await bruno.tontines.savePreuve(groupeId, preuve);
    final relue = await adele.tontines.getPreuve(groupeId, preuve.id);
    expect(relue?.tailleOctets, 2048);
    expect(relue?.imageEncodee, preuve.imageEncodee);

    final declaration = Declaration(
      id: bruno.tontines.nouvelIdDeclaration(groupeId),
      tourId: toursLus.first.id,
      nomId: nom1.id,
      membreId: membreBruno.id,
      montantDeclare: 25000,
      datePaiement: DateTime(2026, 11, 7),
      preuveId: preuve.id,
      statut: StatutDeclaration.enAttente,
      createdAt: DateTime.now(),
    );
    await bruno.tontines.deposerDeclaration(groupeId, declaration);

    // Usurpation : déclarer au nom d'Adèle est refusé par la RLS.
    await expectLater(
      bruno.tontines.deposerDeclaration(
        groupeId,
        Declaration(
          id: bruno.tontines.nouvelIdDeclaration(groupeId),
          tourId: toursLus.first.id,
          nomId: nom2.id,
          membreId: membreAdele.id,
          montantDeclare: 12500,
          datePaiement: DateTime(2026, 11, 7),
          preuveId: preuve.id,
          statut: StatutDeclaration.enAttente,
          createdAt: DateTime.now(),
        ),
      ),
      throwsA(isA<ActionNonAutoriseeException>()),
    );

    // ---- validation par le bureau, d'un bloc
    await expectLater(
      bruno.tontines.validerDeclaration(groupeId, declarationId: declaration.id, montantDu: 25000, penalite: 0),
      throwsA(isA<ActionNonAutoriseeException>()),
    );
    final cotisationId = await adele.tontines.validerDeclaration(
      groupeId,
      declarationId: declaration.id,
      montantDu: 25000,
      penalite: 0,
    );
    final declarations = await bruno.tontines.getDeclarations(groupeId);
    expect(declarations.single.statut, StatutDeclaration.validee);
    final cotisations = await bruno.tontines.getCotisations(groupeId);
    final cotisation = cotisations.singleWhere((c) => c.id == cotisationId);
    expect(cotisation.montantVerse, 25000);
    expect(cotisation.origine, OrigineCotisation.membre);
    expect(cotisation.statut, StatutCotisation.validee);
    expect(cotisation.preuveId, preuve.id);
    await expectLater(
      adele.tontines.validerDeclaration(groupeId, declarationId: declaration.id, montantDu: 25000, penalite: 0),
      throwsA(isA<DonneesInvalidesException>().having((e) => e.details, 'code', 'declaration_not_pending')),
    );

    // ---- cotisation saisie directement par le bureau (demi-nom d'Adèle)
    await adele.tontines.saveCotisation(
      groupeId,
      Cotisation(
        id: adele.tontines.nouvelIdCotisation(groupeId),
        tourId: toursLus.first.id,
        nomId: nom2.id,
        membreId: membreAdele.id,
        montantDu: 12500,
        montantVerse: 12500,
        datePaiement: DateTime(2026, 11, 7),
        origine: OrigineCotisation.administratrice,
        statut: StatutCotisation.validee,
        auteurUid: _adele,
        penalite: 0,
      ),
    );
    expect(await bruno.tontines.getCotisations(groupeId), hasLength(2));

    // ---- réorganisation motivée
    final resultat = const ReorganisateurTours().reorganiser(
      tontine: tontine,
      tours: toursLus,
      anciennePosition: 2,
      nouvellePosition: 1,
      motif: 'Demande du membre',
      auteurUid: _adele,
    );
    await adele.tontines.reorganiserTours(
      groupeId,
      tours: resultat.tours,
      changements: resultat.changements,
      motif: 'Demande du membre',
    );
    final apres = await bruno.tontines.getTours(groupeId);
    expect(apres.first.nomId, nom2.id);
    final changements = await bruno.tontines.getChangements(groupeId);
    expect(changements, hasLength(2));
    expect(changements.map((Changement c) => c.motif).toSet(), {'Demande du membre'});

    // ---- réglages et membres modifiés par le bureau
    await adele.tontines.saveTontine(
      Tontine(
        id: groupeId,
        nom: '${tontine.nom} (2026)',
        adminUid: tontine.adminUid,
        montantParNom: 30000,
        nombreDeNoms: 3,
        datePremiereEcheance: tontine.datePremiereEcheance,
        periodicite: ReglePeriodicite.chaqueMoisJourFixe(5),
        reglePenalite: ReglePenalite.aucune,
        delaiGraceJours: 0,
        valeurPenalite: null,
        modeParts: ModeParts.partEgale,
      ),
    );
    final modifiee = (await bruno.tontines.getTontine(groupeId))!;
    expect(modifiee.montantParNom, 30000);
    expect(modifiee.modeParts, ModeParts.partEgale);
    expect(modifiee.reglePenalite, ReglePenalite.aucune);

    await adele.tontines.saveMembre(
      groupeId,
      Membre(
        id: membreBruno.id,
        nomComplet: 'Bruno Ekotto Mballa',
        whatsapp: membreBruno.whatsapp,
        uid: membreBruno.uid,
        actif: false,
      ),
    );
    final brunoModifie = (await adele.tontines.getMembres(groupeId)).singleWhere((m) => m.id == membreBruno.id);
    expect(brunoModifie.nomComplet, 'Bruno Ekotto Mballa');
    expect(brunoModifie.actif, isFalse);
    expect(brunoModifie.uid, _bruno, reason: 'le compte rattaché ne change jamais par ce biais');

    // Contestation d'une nouvelle déclaration.
    final declaration2 = Declaration(
      id: bruno.tontines.nouvelIdDeclaration(groupeId),
      tourId: apres.first.id,
      nomId: nom1.id,
      membreId: membreBruno.id,
      montantDeclare: 1000,
      datePaiement: DateTime(2026, 11, 8),
      preuveId: preuve.id,
      statut: StatutDeclaration.enAttente,
      createdAt: DateTime.now(),
    );
    final statutTour = apres.first.statut;
    if (statutTour == StatutTour.enCours) {
      await bruno.tontines.deposerDeclaration(groupeId, declaration2);
      await adele.tontines.contesterDeclaration(groupeId, declarationId: declaration2.id, motif: 'Preuve illisible');
      final contestee = (await bruno.tontines.getDeclarations(groupeId)).singleWhere((d) => d.id == declaration2.id);
      expect(contestee.statut, StatutDeclaration.contestee);
      expect(contestee.motifContestation, 'Preuve illisible');
    }
  }, skip: ignore);

  test('les adhésions listent chaque groupe avec ses rôles', () async {
    final chantal = _comme(_chantal, stockage);
    final g1 = await chantal.groupes.creerTontine(tontine: _brouillon('Groupe A'), nomCompletAdmin: 'Chantal Ngo');
    final g2 = await chantal.groupes.creerTontine(tontine: _brouillon('Groupe B'), nomCompletAdmin: 'Chantal Ngo');

    final adhesions = await chantal.groupes.watchAdhesions(_chantal).first;
    final ids = adhesions.map((a) => a.groupeId).toList();
    expect(ids, containsAll([g1, g2]));
    expect(adhesions.firstWhere((a) => a.groupeId == g2).nomGroupe, 'Groupe B');
  }, skip: ignore);

  test('suppression de compte : refusée au seul propriétaire, puis fiche anonymisée', () async {
    final adele = _comme(_adele, stockage);
    final dora = _comme(_dora, stockage);
    final groupeId = await adele.groupes.creerTontine(tontine: _brouillon('Groupe D'), nomCompletAdmin: 'Adèle');
    final invitation = await adele.tontines.inviterMembre(groupeId, nomComplet: 'Dora Fouda', email: 'dora@example.com');
    await dora.groupes.rejoindre(invitation.code);

    // Dora crée son propre groupe où elle invite Adèle : seule propriétaire, elle ne peut pas partir.
    final groupeDora = await dora.groupes.creerTontine(tontine: _brouillon('Groupe de Dora'), nomCompletAdmin: 'Dora');
    final invitationAdele = await dora.tontines.inviterMembre(groupeDora, nomComplet: 'Adèle', email: 'adele@example.com');
    await adele.groupes.rejoindre(invitationAdele.code);
    await expectLater(dora.groupes.supprimerMonCompte(), throwsA(isA<TransfertProprieteRequisException>()));

    // Dora transmet la propriété à Adèle : elle peut alors partir.
    await _db(_dora).rpc('set_member_roles', params: {
      'p_member_id': invitationAdele.membreId,
      'p_roles': ['owner'],
    });
    await dora.groupes.supprimerMonCompte();

    final fiche = (await adele.tontines.getMembres(groupeId)).singleWhere((m) => m.id == invitation.membreId);
    expect(fiche.uid, isNull);
    expect(fiche.email, isNull);
    expect(fiche.nomComplet, 'Dora Fouda');
  }, skip: ignore);

  test('un tour généré puis remis ne peut plus être déplacé', () async {
    final adele = _comme(_adele, stockage);
    final groupeId = await adele.groupes.creerTontine(tontine: _brouillon('Groupe C'), nomCompletAdmin: 'Adèle');
    final membre = (await adele.tontines.getMembres(groupeId)).single;
    for (final position in [1, 2]) {
      await adele.tontines.saveNom(
        groupeId,
        Nom(
          id: adele.tontines.nouvelIdNom(groupeId),
          position: position,
          libelle: 'Nom $position',
          parts: [Part(membreId: membre.id, fraction: 1)],
        ),
      );
    }
    final tontine = (await adele.tontines.getTontine(groupeId))!;
    final tours = const GenerateurEcheancier().generer(
      tontine: tontine,
      noms: await adele.tontines.getNoms(groupeId),
      nouvelId: (_) => adele.tontines.nouvelIdTour(groupeId),
    );
    await adele.tontines.saveTours(groupeId, tours);
    final premier = tours.first;
    await adele.tontines.saveTour(
      groupeId,
      Tour(
        id: premier.id,
        nomId: premier.nomId,
        position: premier.position,
        datePrevue: premier.datePrevue,
        statut: StatutTour.remis,
        montantRemis: 50000,
      ),
    );

    await expectLater(
      adele.tontines.reorganiserTours(
        groupeId,
        tours: [
          Tour(id: tours[0].id, nomId: tours[0].nomId, position: 2, datePrevue: tours[1].datePrevue, statut: StatutTour.remis),
          Tour(id: tours[1].id, nomId: tours[1].nomId, position: 1, datePrevue: tours[0].datePrevue, statut: StatutTour.aVenir),
        ],
        changements: [
          Changement(id: 'x', tourId: tours[0].id, anciennePosition: 1, nouvellePosition: 2, motif: 'x', auteurUid: _adele, createdAt: DateTime.now()),
        ],
        motif: 'Erreur',
      ),
      throwsA(isA<DonneesInvalidesException>().having((e) => e.details, 'code', 'turn_already_paid')),
    );
    expect((await adele.tontines.getTours(groupeId)).first.montantRemis, 50000);
  }, skip: ignore);
}
