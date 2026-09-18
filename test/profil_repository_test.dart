import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/data/datasources/profil_firestore_datasource.dart';
import 'package:tontinefacile/data/models/invitation_model.dart';
import 'package:tontinefacile/data/models/profil_model.dart';
import 'package:tontinefacile/data/repositories/profil_repository_impl.dart';
import 'package:tontinefacile/domain/entities/invitation.dart';
import 'package:tontinefacile/domain/entities/profil.dart';

void main() {
  test('le repository convertit un profil existant en entité', () async {
    final source = FakeProfilDataSource(
      profils: {
        'uid-1': const ProfilModel(
          uid: 'uid-1',
          tontineId: 'tontine-1',
          membreId: 'membre-1',
        ),
      },
    );
    final repository = FirestoreProfilRepository(dataSource: source);

    final profil = await repository.getProfil('uid-1');

    expect(profil, isA<Profil>());
    expect(profil?.tontineId, 'tontine-1');
    expect(profil?.membreId, 'membre-1');
  });

  test('le repository renvoie null pour un profil absent', () async {
    final repository = FirestoreProfilRepository(
      dataSource: FakeProfilDataSource(),
    );

    expect(await repository.getProfil('inconnu'), isNull);
  });

  test('le repository écrit un profil via le datasource', () async {
    final source = FakeProfilDataSource();
    final repository = FirestoreProfilRepository(dataSource: source);

    await repository.saveProfil(
      const Profil(uid: 'uid-2', tontineId: 'tontine-2', membreId: 'm-2'),
    );

    expect(source.profils['uid-2']?.tontineId, 'tontine-2');
  });

  test('le repository résout une invitation existante', () async {
    final source = FakeProfilDataSource(
      invitations: {
        'ABC123': const InvitationModel(
          code: 'ABC123',
          tontineId: 'tontine-1',
          membreId: 'membre-1',
          nomTontine: 'Cercle des amies',
          nombreMembres: 3,
        ),
      },
    );
    final repository = FirestoreProfilRepository(dataSource: source);

    final invitation = await repository.getInvitation('ABC123');

    expect(invitation, isA<Invitation>());
    expect(invitation?.membreId, 'membre-1');
  });

  test('le repository écrit une invitation via le datasource', () async {
    final source = FakeProfilDataSource();
    final repository = FirestoreProfilRepository(dataSource: source);

    await repository.saveInvitation(
      const Invitation(
        code: 'XYZ789',
        tontineId: 't-1',
        membreId: 'm-1',
        nomTontine: 'Cercle des amies',
        nombreMembres: 3,
      ),
    );

    expect(source.invitations['XYZ789']?.tontineId, 't-1');
  });
}

class FakeProfilDataSource implements ProfilDataSource {
  FakeProfilDataSource({
    Map<String, ProfilModel> profils = const {},
    Map<String, InvitationModel> invitations = const {},
  })  : profils = Map.of(profils),
        invitations = Map.of(invitations);

  final Map<String, ProfilModel> profils;
  final Map<String, InvitationModel> invitations;

  @override
  Future<ProfilModel?> getProfil(String uid) async => profils[uid];

  @override
  Stream<ProfilModel?> watchProfil(String uid) => Stream.value(profils[uid]);

  @override
  Future<void> saveProfil(ProfilModel profil) async =>
      profils[profil.uid] = profil;

  @override
  Future<InvitationModel?> getInvitation(String code) async =>
      invitations[code];

  @override
  Future<void> saveInvitation(InvitationModel invitation) async =>
      invitations[invitation.code] = invitation;
}
