// Doubles en mémoire partagés par les tests : repositories, service
// d'authentification et préférences de session.
import 'dart:async';

import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/repositories/groupes_repository.dart';
import 'package:tontinefacile/data/repositories/tontine_repository.dart';
import 'package:tontinefacile/data/services/auth_service.dart';
import 'package:tontinefacile/data/services/preferences_session.dart';
import 'package:tontinefacile/domain/entities/adhesion.dart';
import 'package:tontinefacile/domain/entities/app_user.dart';
import 'package:tontinefacile/domain/entities/changement.dart';
import 'package:tontinefacile/domain/entities/cotisation.dart';
import 'package:tontinefacile/domain/entities/declaration.dart';
import 'package:tontinefacile/domain/entities/invitation.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/nom.dart';
import 'package:tontinefacile/domain/entities/preuve.dart';
import 'package:tontinefacile/domain/entities/tontine.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/role_membre.dart';
import 'package:tontinefacile/domain/enums/statut_cotisation.dart';
import 'package:tontinefacile/domain/enums/origine_cotisation.dart';
import 'package:tontinefacile/domain/enums/statut_declaration.dart';
import 'package:tontinefacile/domain/enums/type_groupe.dart';

class FakeTontineRepository implements TontineRepository {
  final Map<String, Tontine> saved = {};
  final Map<String, Membre> membres = {};
  final Map<String, Nom> noms = {};
  final Map<String, Tour> tours = {};
  final Map<String, Cotisation> cotisations = {};
  final Map<String, Declaration> declarations = {};
  final Map<String, Preuve> preuves = {};
  final Map<String, Changement> changements = {};
  final Map<String, String> codesInvitation = {};
  var _nextId = 0;

  String _id(String prefixe) => '$prefixe-${_nextId++}';

  List<Tour> get _toursOrdonnes =>
      tours.values.toList()..sort((a, b) => a.position.compareTo(b.position));

  @override
  Future<Tontine?> getTontine(String groupeId) async => saved[groupeId];
  @override
  Stream<Tontine?> watchTontine(String groupeId) => Stream.value(saved[groupeId]);
  @override
  Future<void> saveTontine(Tontine tontine) async => saved[tontine.id] = tontine;

  @override
  Future<List<Membre>> getMembres(String groupeId) async => membres.values.toList();
  @override
  Stream<List<Membre>> watchMembres(String groupeId) => Stream.value(membres.values.toList());
  @override
  Future<void> saveMembre(String groupeId, Membre membre) async => membres[membre.id] = membre;

  @override
  Future<Invitation> inviterMembre(
    String groupeId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) async {
    final code = 'CODE${_nextId.toString().padLeft(2, '0')}';
    final membre = Membre(
      id: _id('membre'),
      nomComplet: nomComplet,
      email: email,
      whatsapp: whatsapp,
      codeInvitation: code,
    );
    membres[membre.id] = membre;
    codesInvitation[code] = membre.id;
    return Invitation(
      code: code,
      tontineId: groupeId,
      membreId: membre.id,
      nomTontine: saved[groupeId]?.nom ?? '',
      nombreMembres: membres.length,
    );
  }

  @override
  String nouvelIdNom(String groupeId) => _id('nom');
  @override
  Future<List<Nom>> getNoms(String groupeId) async => noms.values.toList();
  @override
  Stream<List<Nom>> watchNoms(String groupeId) => Stream.value(noms.values.toList());
  @override
  Future<void> saveNom(String groupeId, Nom nom) async => noms[nom.id] = nom;

  @override
  String nouvelIdTour(String groupeId) => _id('tour');
  @override
  Future<List<Tour>> getTours(String groupeId) async => _toursOrdonnes;
  @override
  Stream<List<Tour>> watchTours(String groupeId) => Stream.value(_toursOrdonnes);
  @override
  Future<void> saveTour(String groupeId, Tour tour) async => tours[tour.id] = tour;
  @override
  Future<void> saveTours(String groupeId, List<Tour> liste) async {
    for (final tour in liste) {
      tours[tour.id] = tour;
    }
  }

  @override
  Future<void> reorganiserTours(
    String groupeId, {
    required List<Tour> tours,
    required List<Changement> changements,
    required String motif,
  }) async {
    for (final tour in tours) {
      this.tours[tour.id] = tour;
    }
    for (final changement in changements) {
      this.changements[changement.id] = changement;
    }
  }

  @override
  String nouvelIdCotisation(String groupeId) => _id('cotisation');
  @override
  Future<List<Cotisation>> getCotisations(String groupeId) async => cotisations.values.toList();
  @override
  Stream<List<Cotisation>> watchCotisations(String groupeId) =>
      Stream.value(cotisations.values.toList());
  @override
  Future<void> saveCotisation(String groupeId, Cotisation cotisation) async =>
      cotisations[cotisation.id] = cotisation;

  @override
  String nouvelIdDeclaration(String groupeId) => _id('declaration');
  @override
  Future<List<Declaration>> getDeclarations(String groupeId) async => declarations.values.toList();
  @override
  Stream<List<Declaration>> watchDeclarations(String groupeId) =>
      Stream.value(declarations.values.toList());
  @override
  Future<void> deposerDeclaration(String groupeId, Declaration declaration) async =>
      declarations[declaration.id] = declaration;

  /// Même effet que la fonction SQL `validate_declaration`.
  @override
  Future<String> validerDeclaration(
    String groupeId, {
    required String declarationId,
    required int montantDu,
    required int penalite,
  }) async {
    final declaration = declarations[declarationId]!;
    if (declaration.statut != StatutDeclaration.enAttente) {
      throw const DonneesInvalidesException('declaration_not_pending');
    }
    final cotisation = Cotisation(
      id: _id('cotisation'),
      tourId: declaration.tourId,
      nomId: declaration.nomId,
      membreId: declaration.membreId,
      montantDu: montantDu,
      montantVerse: declaration.montantDeclare,
      datePaiement: declaration.datePaiement,
      origine: OrigineCotisation.membre,
      statut: StatutCotisation.validee,
      auteurUid: 'serveur',
      penalite: penalite,
      preuveId: declaration.preuveId,
    );
    cotisations[cotisation.id] = cotisation;
    declarations[declarationId] = _avecStatut(declaration, StatutDeclaration.validee);
    return cotisation.id;
  }

  @override
  Future<void> contesterDeclaration(
    String groupeId, {
    required String declarationId,
    required String motif,
  }) async {
    declarations[declarationId] =
        _avecStatut(declarations[declarationId]!, StatutDeclaration.contestee, motif: motif);
  }

  Declaration _avecStatut(Declaration d, StatutDeclaration statut, {String? motif}) => Declaration(
        id: d.id,
        tourId: d.tourId,
        nomId: d.nomId,
        membreId: d.membreId,
        montantDeclare: d.montantDeclare,
        datePaiement: d.datePaiement,
        preuveId: d.preuveId,
        statut: statut,
        motifContestation: motif ?? d.motifContestation,
        createdAt: d.createdAt,
        updatedAt: DateTime.now(),
      );

  @override
  String nouvelIdPreuve(String groupeId) => _id('preuve');
  @override
  Future<void> savePreuve(String groupeId, Preuve preuve) async => preuves[preuve.id] = preuve;
  @override
  Future<Preuve?> getPreuve(String groupeId, String preuveId) async => preuves[preuveId];

  @override
  Future<List<Changement>> getChangements(String groupeId) async => changements.values.toList();
  @override
  Stream<List<Changement>> watchChangements(String groupeId) =>
      Stream.value(changements.values.toList());
}

/// Service d'authentification en mémoire. [confirmationRequise] simule un
/// projet où l'email doit être confirmé avant toute session.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? utilisateur, this.confirmationRequise = false})
      : _currentUser = utilisateur {
    _controleur.add(utilisateur);
  }

  AppUser? _currentUser;
  bool confirmationRequise;
  final comptes = <String, String>{};
  final confirmationsRenvoyees = <String>[];
  final _controleur = StreamController<AppUser?>.broadcast();
  var _prochainUid = 0;

  void connecterDirectement(AppUser? utilisateur) {
    _currentUser = utilisateur;
    _controleur.add(utilisateur);
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _controleur.stream;
  }

  @override
  Future<ResultatInscription> signUp({required String email, required String password}) async {
    if (comptes.containsKey(email)) throw const EmailAlreadyInUseException();
    if (password.length < 6) throw const WeakPasswordException();
    comptes[email] = password;
    final utilisateur = AppUser(uid: 'uid-${_prochainUid++}', email: email, emailVerified: !confirmationRequise);
    if (!confirmationRequise) connecterDirectement(utilisateur);
    return (utilisateur: utilisateur, connecte: !confirmationRequise);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    if (comptes[email] != password) throw const InvalidCredentialsException();
    final utilisateur = AppUser(uid: 'uid-$email', email: email, emailVerified: true);
    connecterDirectement(utilisateur);
    return utilisateur;
  }

  @override
  Future<AppUser?> signInWithGoogle() async => null;
  @override
  Future<AppUser?> signInWithApple() async => null;

  @override
  Future<void> signOut() async => connecterDirectement(null);

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> resendConfirmation(String email) async => confirmationsRenvoyees.add(email);

  final _recuperations = StreamController<void>.broadcast();
  String? dernierMotDePasse;

  void ouvrirLienReinitialisation() => _recuperations.add(null);

  @override
  Stream<void> get passwordRecovery => _recuperations.stream;

  @override
  Future<void> updatePassword(String password) async => dernierMotDePasse = password;

  @override
  Future<AppUser?> reloadUser() async => _currentUser;
}

/// Groupes en mémoire : reproduit les règles des fonctions SQL utiles aux
/// tests (code introuvable, déjà utilisé, déjà membre).
class FakeGroupesRepository implements GroupesRepository {
  FakeGroupesRepository({this.tontines, this.auth});

  /// Si fourni, les tontines créées y sont aussi enregistrées.
  final FakeTontineRepository? tontines;

  /// Si fourni, le compte courant est celui de ce service (comme côté
  /// serveur, où `auth.uid()` vient de la session).
  final AuthService? auth;
  final adhesionsParUid = <String, List<Adhesion>>{};
  final invitations = <String, ({String groupeId, String membreId, String nomGroupe})>{};
  final codesUtilises = <String>{};
  final _changements = StreamController<String>.broadcast();
  var _prochainId = 0;
  String? _uid;
  String? get uidCourant => auth?.currentUser?.uid ?? _uid;
  set uidCourant(String? uid) => _uid = uid;

  void ajouterAdhesion(String uid, Adhesion adhesion) {
    adhesionsParUid.putIfAbsent(uid, () => []).add(adhesion);
    _changements.add(uid);
  }

  @override
  Stream<List<Adhesion>> watchAdhesions(String uid) async* {
    yield List.of(adhesionsParUid[uid] ?? const []);
    yield* _changements.stream.where((u) => u == uid).map((_) => List.of(adhesionsParUid[uid]!));
  }

  @override
  Future<String> creerTontine({required Tontine tontine, required String nomCompletAdmin}) async {
    final uid = uidCourant;
    if (uid == null) throw const SignInRequiredException();
    final groupeId = 'groupe-${_prochainId++}';
    final membreId = 'membre-admin-$groupeId';
    tontines?.saved[groupeId] = Tontine(
      id: groupeId,
      nom: tontine.nom,
      adminUid: uid,
      montantParNom: tontine.montantParNom,
      nombreDeNoms: tontine.nombreDeNoms,
      datePremiereEcheance: tontine.datePremiereEcheance,
      periodicite: tontine.periodicite,
      reglePenalite: tontine.reglePenalite,
      delaiGraceJours: tontine.delaiGraceJours,
      valeurPenalite: tontine.valeurPenalite,
      modeParts: tontine.modeParts,
    );
    ajouterAdhesion(
      uid,
      Adhesion(
        groupeId: groupeId,
        membreId: membreId,
        nomGroupe: tontine.nom,
        type: TypeGroupe.tontine,
        roles: const {RoleMembre.proprietaire, RoleMembre.tresorier},
      ),
    );
    return groupeId;
  }

  @override
  Future<ApercuInvitation?> apercuInvitation(String code) async {
    final invitation = invitations[code];
    if (invitation == null) return null;
    return (nomGroupe: invitation.nomGroupe, nombreMembres: 3, dejaUtilisee: codesUtilises.contains(code));
  }

  var compteSupprime = false;
  bool refuserSuppression = false;

  @override
  Future<void> supprimerMonCompte() async {
    if (refuserSuppression) throw const TransfertProprieteRequisException();
    compteSupprime = true;
    adhesionsParUid.remove(uidCourant);
  }

  @override
  Future<({String groupeId, String membreId})> rejoindre(String code) async {
    final uid = uidCourant;
    if (uid == null) throw const SignInRequiredException();
    final invitation = invitations[code];
    if (invitation == null) throw const InvitationIntrouvableException();
    if (codesUtilises.contains(code)) throw const InvitationDejaUtiliseeException();
    if ((adhesionsParUid[uid] ?? const []).any((a) => a.groupeId == invitation.groupeId)) {
      throw const DejaMembreException();
    }
    codesUtilises.add(code);
    ajouterAdhesion(
      uid,
      Adhesion(
        groupeId: invitation.groupeId,
        membreId: invitation.membreId,
        nomGroupe: invitation.nomGroupe,
        type: TypeGroupe.tontine,
        roles: const {RoleMembre.membre},
      ),
    );
    return (groupeId: invitation.groupeId, membreId: invitation.membreId);
  }
}

class FakePreferencesSession implements PreferencesSession {
  final _groupes = <String, String>{};
  final _changements = StreamController<String>.broadcast();
  String? _code;

  @override
  String? groupeCourant(String uid) => _groupes[uid];

  @override
  Future<void> choisirGroupe(String uid, String groupeId) async {
    _groupes[uid] = groupeId;
    _changements.add(uid);
  }

  @override
  Stream<String> get changementsGroupe => _changements.stream;

  @override
  String? get codeInvitationEnAttente => _code;

  @override
  Future<void> setCodeInvitationEnAttente(String? code) async => _code = code;
}
