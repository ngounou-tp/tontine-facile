import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/adhesion.dart';
import '../../domain/entities/tontine.dart';
import '../supabase/supabase_codecs.dart';
import '../supabase/supabase_errors.dart';
import '../supabase/table_changes.dart';
import 'groupes_repository.dart';

class SupabaseGroupesRepository implements GroupesRepository {
  SupabaseGroupesRepository({required this._db, required this._changes});

  final PostgrestClient _db;
  final TableChanges _changes;

  Future<List<Adhesion>> _adhesions(String uid) => guardSupabase(() async {
        final lignes = await _db
            .from('group_members')
            .select('id, group_id, roles, active, groups(name, kind)')
            .eq('user_id', uid)
            .order('created_at', ascending: true);
        return lignes.map(adhesionFromRow).toList(growable: false);
      });

  @override
  Stream<List<Adhesion>> watchAdhesions(String uid) {
    late final StreamController<List<Adhesion>> controleur;
    StreamSubscription<void>? abonnement;
    var actif = true;

    Future<void> emettre() async {
      try {
        final adhesions = await _adhesions(uid);
        if (actif) controleur.add(adhesions);
      } catch (error, stackTrace) {
        if (actif) controleur.addError(error, stackTrace);
      }
    }

    controleur = StreamController<List<Adhesion>>(
      onListen: () {
        emettre();
        abonnement = _changes
            .watch('group_members', column: 'user_id', value: uid)
            .listen((_) => emettre());
      },
      onCancel: () async {
        actif = false;
        await abonnement?.cancel();
      },
    );
    return controleur.stream;
  }

  @override
  Future<String> creerTontine({required Tontine tontine, required String nomCompletAdmin}) =>
      guardSupabase(() async {
        final id = await _db.rpc('create_tontine', params: {
          'p_name': tontine.nom,
          'p_admin_full_name': nomCompletAdmin,
          'p_settings': reglagesToRow(tontine),
        });
        return id as String;
      });

  @override
  Future<ApercuInvitation?> apercuInvitation(String code) => guardSupabase(() async {
        final lignes = await _db.rpc('invitation_preview', params: {'p_code': code.trim()});
        final liste = (lignes as List).cast<Map<String, dynamic>>();
        if (liste.isEmpty) return null;
        final ligne = liste.single;
        return (
          nomGroupe: ligne['group_name'] as String,
          nombreMembres: decodeInt(ligne['member_count']),
          dejaUtilisee: ligne['claimed'] as bool? ?? false,
        );
      });

  @override
  Future<({String groupeId, String membreId})> rejoindre(String code) => guardSupabase(() async {
        final lignes = await _db.rpc('claim_invitation', params: {'p_code': code.trim()});
        final ligne = (lignes as List).cast<Map<String, dynamic>>().single;
        return (groupeId: ligne['group_id'] as String, membreId: ligne['member_id'] as String);
      });
}
