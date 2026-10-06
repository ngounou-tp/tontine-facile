import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/services/supabase_auth_service.dart';
import 'package:tontinefacile/data/supabase/supabase_codecs.dart';
import 'package:tontinefacile/data/supabase/supabase_errors.dart';
import 'package:tontinefacile/domain/entities/tour.dart';
import 'package:tontinefacile/domain/enums/mode_parts.dart';
import 'package:tontinefacile/domain/enums/regle_penalite.dart';
import 'package:tontinefacile/domain/enums/role_membre.dart';
import 'package:tontinefacile/domain/enums/statut_tour.dart';
import 'package:tontinefacile/domain/enums/type_groupe.dart';
import 'package:tontinefacile/domain/value_objects/regle_periodicite.dart';

void main() {
  group('dates métier', () {
    test("un jour reste le même jour, sans décalage de fuseau", () {
      expect(encodeDate(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(decodeDate('2026-01-05'), DateTime(2026, 1, 5));
      expect(decodeDate('2026-01-05T00:00:00+00:00'), DateTime(2026, 1, 5));
    });

    test('les montants arrivent parfois en texte (bigint)', () {
      expect(decodeInt('25000'), 25000);
      expect(decodeInt(25000), 25000);
      expect(decodeDouble('0.50000000'), 0.5);
    });
  });

  test('groupe + réglages → tontine, et retour', () {
    final tontine = tontineFromRows(
      {'id': 'g1', 'name': 'Njangi', 'created_by': 'uid-1'},
      {
        'amount_per_name': 25000,
        'names_count': 12,
        'first_due_date': '2026-11-01',
        'periodicity': {'type': 'chaqueSemaine', 'jourDeLaSemaine': 6},
        'penalty_rule': 'forfaitaire',
        'penalty_value': 1000,
        'grace_days': 2,
        'shares_mode': 'PROPORTIONAL',
      },
    );
    expect(tontine.nom, 'Njangi');
    expect(tontine.periodicite, isA<RegleChaqueSemaine>());
    expect(tontine.reglePenalite, ReglePenalite.forfaitaire);
    expect(tontine.modeParts, ModeParts.proportionnel);

    final ligne = reglagesToRow(tontine);
    expect(ligne['first_due_date'], '2026-11-01');
    expect(ligne['shares_mode'], 'PROPORTIONAL');
    expect(ligne['periodicity'], {'type': 'chaqueSemaine', 'jourDeLaSemaine': 6});
  });

  test('adhésion : groupe joint et rôles', () {
    final adhesion = adhesionFromRow({
      'id': 'm1',
      'group_id': 'g1',
      'roles': ['member', 'auditor'],
      'active': true,
      'groups': {'name': 'Njangi', 'kind': 'tontine'},
    });
    expect(adhesion.roles, {RoleMembre.membre, RoleMembre.commissaire});
    expect(adhesion.type, TypeGroupe.tontine);
    expect(adhesion.estGestionnaire, isFalse);
  });

  test('nom et ses parts (ordre stable)', () {
    final nom = nomFromRow({
      'id': 'n1',
      'position': 2,
      'label': 'Nom 2',
      'tontine_name_shares': [
        {'member_id': 'm2', 'fraction': '0.50000000'},
        {'member_id': 'm1', 'fraction': 0.5},
      ],
    });
    expect(nom.parts.map((p) => p.membreId), ['m1', 'm2']);
    expect(nom.parts.map((p) => p.fraction), [0.5, 0.5]);
  });

  test('tour : aller-retour', () {
    final tour = Tour(
      id: 't1',
      nomId: 'n1',
      position: 3,
      datePrevue: DateTime(2026, 12, 5),
      statut: StatutTour.remis,
      montantRemis: 75000,
    );
    final relu = tourFromRow(tourToRow('g1', tour));
    expect(relu.datePrevue, DateTime(2026, 12, 5));
    expect(relu.statut, StatutTour.remis);
    expect(relu.montantRemis, 75000);
  });

  group('erreurs serveur → erreurs de l’app', () {
    sb.PostgrestException erreur(String message, [String code = 'P0001']) =>
        sb.PostgrestException(message: message, code: code);

    test('codes métier des fonctions SQL', () {
      expect(mapSupabaseError(erreur('invitation_not_found')), isA<InvitationIntrouvableException>());
      expect(mapSupabaseError(erreur('invitation_already_used')), isA<InvitationDejaUtiliseeException>());
      expect(mapSupabaseError(erreur('already_member')), isA<DejaMembreException>());
      expect(mapSupabaseError(erreur('forbidden', '42501')), isA<ActionNonAutoriseeException>());
      expect(mapSupabaseError(erreur('names_quota_exceeded')), isA<NamesQuotaExceededException>());
      expect(
        mapSupabaseError(erreur('shares_must_total_one')),
        isA<DonneesInvalidesException>().having((e) => e.message, 'message', contains('100')),
      );
    });

    test('un refus RLS devient « action non autorisée »', () {
      expect(
        mapSupabaseError(erreur('new row violates row-level security policy', '42501')),
        isA<ActionNonAutoriseeException>(),
      );
    });

    test('les erreurs déjà typées passent telles quelles', () {
      const deja = InvalidCredentialsException();
      expect(identical(mapSupabaseError(deja), deja), isTrue);
    });
  });

  group('erreurs Supabase Auth', () {
    AuthException traduire(String? code, [String? statut]) =>
        mapSupabaseAuthException(sb.AuthApiException('x', code: code, statusCode: statut));

    test('identifiants : même message pour compte inconnu et mot de passe faux', () {
      expect(traduire('invalid_credentials'), isA<InvalidCredentialsException>());
      expect(traduire('user_not_found'), isA<InvalidCredentialsException>());
    });

    test('cas courants', () {
      expect(traduire('user_already_exists'), isA<EmailAlreadyInUseException>());
      expect(traduire('weak_password'), isA<WeakPasswordException>());
      expect(traduire('email_not_confirmed'), isA<EmailNonConfirmeException>());
      expect(traduire(null, '429'), isA<TooManyRequestsException>());
    });

    test('code inconnu : conservé pour le diagnostic', () {
      expect(traduire('nouveau_code'), isA<UnknownAuthException>().having((e) => e.details, 'details', 'nouveau_code'));
    });
  });
}
