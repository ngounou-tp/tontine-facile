import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/changement.dart';
import '../../domain/entities/cotisation.dart';
import '../../domain/entities/declaration.dart';
import '../../domain/entities/invitation.dart';
import '../../domain/entities/membre.dart';
import '../../domain/entities/nom.dart';
import '../../domain/entities/preuve.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/entities/tour.dart';
import '../supabase/stockage_preuves.dart';
import '../supabase/supabase_codecs.dart';
import '../supabase/supabase_errors.dart';
import '../supabase/table_changes.dart';
import 'tontine_repository.dart';

/// [TontineRepository] sur Supabase : lectures et écritures via PostgREST
/// (protégées par la RLS), opérations multi-lignes via les fonctions SQL,
/// mises à jour en direct via [TableChanges], photos via [StockagePreuves].
class SupabaseTontineRepository implements TontineRepository {
  SupabaseTontineRepository({
    required this._db,
    required this._changes,
    required this._stockage,
    this._uuid = const Uuid(),
  });

  final PostgrestClient _db;
  final TableChanges _changes;
  final StockagePreuves _stockage;
  final Uuid _uuid;

  String _nouvelId() => _uuid.v4();

  /// Flux « charger, puis recharger à chaque changement » sur une ou
  /// plusieurs tables d'un groupe.
  Stream<T> _watch<T>(
    String groupeId,
    List<String> tables,
    Future<T> Function() charger, {
    String Function(String table)? colonne,
  }) {
    late final StreamController<T> controleur;
    final abonnements = <StreamSubscription<void>>[];
    var actif = true;

    Future<void> emettre() async {
      try {
        final valeur = await charger();
        if (actif) controleur.add(valeur);
      } catch (error, stackTrace) {
        if (actif) controleur.addError(mapSupabaseError(error), stackTrace);
      }
    }

    controleur = StreamController<T>(
      onListen: () {
        emettre();
        for (final table in tables) {
          abonnements.add(
            _changes
                .watch(table, column: colonne?.call(table) ?? 'group_id', value: groupeId)
                .listen((_) => emettre()),
          );
        }
      },
      onCancel: () async {
        actif = false;
        for (final abonnement in abonnements) {
          await abonnement.cancel();
        }
      },
    );
    return controleur.stream;
  }

  // ------------------------------------------------------------- tontine

  @override
  Future<Tontine?> getTontine(String groupeId) => guardSupabase(() async {
        final groupe = await _db.from('groups').select().eq('id', groupeId).maybeSingle();
        if (groupe == null) return null;
        final reglages =
            await _db.from('tontine_settings').select().eq('group_id', groupeId).maybeSingle();
        if (reglages == null) return null;
        return tontineFromRows(groupe, reglages);
      });

  @override
  Stream<Tontine?> watchTontine(String groupeId) => _watch(
        groupeId,
        const ['groups', 'tontine_settings'],
        () => getTontine(groupeId),
        colonne: (table) => table == 'groups' ? 'id' : 'group_id',
      );

  @override
  Future<void> saveTontine(Tontine tontine) => guardSupabase(() async {
        await _db.from('groups').update({'name': tontine.nom}).eq('id', tontine.id);
        await _db
            .from('tontine_settings')
            .update({...reglagesToRow(tontine), 'updated_at': DateTime.now().toUtc().toIso8601String()})
            .eq('group_id', tontine.id);
      });

  // -------------------------------------------------------------- membres

  @override
  Future<List<Membre>> getMembres(String groupeId) => guardSupabase(() async {
        final lignes = await _db
            .from('group_members')
            .select()
            .eq('group_id', groupeId)
            .order('created_at', ascending: true);
        return lignes.map(membreFromRow).toList(growable: false);
      });

  @override
  Stream<List<Membre>> watchMembres(String groupeId) =>
      _watch(groupeId, const ['group_members'], () => getMembres(groupeId));

  @override
  Future<void> saveMembre(String groupeId, Membre membre) => guardSupabase(() async {
        await _db.from('group_members').update({
          'full_name': membre.nomComplet,
          'email': membre.email,
          'whatsapp': membre.whatsapp,
          'active': membre.actif,
        }).eq('id', membre.id).eq('group_id', groupeId);
      });

  @override
  Future<Invitation> inviterMembre(
    String groupeId, {
    required String nomComplet,
    String? email,
    String? whatsapp,
  }) =>
      guardSupabase(() async {
        final resultat = await _db.rpc('invite_member', params: {
          'p_group_id': groupeId,
          'p_full_name': nomComplet,
          'p_email': email,
          'p_whatsapp': whatsapp,
        });
        final ligne = (resultat as List).cast<Map<String, dynamic>>().single;
        return Invitation(
          code: ligne['code'] as String,
          tontineId: groupeId,
          membreId: ligne['member_id'] as String,
          nomTontine: '',
          nombreMembres: 0,
        );
      });

  // ----------------------------------------------------------------- noms

  @override
  String nouvelIdNom(String groupeId) => _nouvelId();

  @override
  Future<List<Nom>> getNoms(String groupeId) => guardSupabase(() async {
        final lignes = await _db
            .from('tontine_names')
            .select('*, tontine_name_shares(member_id, fraction)')
            .eq('group_id', groupeId)
            .order('position', ascending: true);
        return lignes.map(nomFromRow).toList(growable: false);
      });

  @override
  Stream<List<Nom>> watchNoms(String groupeId) =>
      _watch(groupeId, const ['tontine_names', 'tontine_name_shares'], () => getNoms(groupeId));

  @override
  Future<void> saveNom(String groupeId, Nom nom) => guardSupabase(() async {
        await _db.rpc('save_tontine_name', params: {
          'p_group_id': groupeId,
          'p_name_id': nom.id,
          'p_position': nom.position,
          'p_label': nom.libelle,
          'p_shares': partsToJson(nom.parts),
        });
      });

  // ---------------------------------------------------------------- tours

  @override
  String nouvelIdTour(String groupeId) => _nouvelId();

  @override
  Future<List<Tour>> getTours(String groupeId) => guardSupabase(() async {
        final lignes = await _db
            .from('tontine_turns')
            .select()
            .eq('group_id', groupeId)
            .order('position', ascending: true);
        return lignes.map(tourFromRow).toList(growable: false);
      });

  @override
  Stream<List<Tour>> watchTours(String groupeId) =>
      _watch(groupeId, const ['tontine_turns'], () => getTours(groupeId));

  @override
  Future<void> saveTour(String groupeId, Tour tour) => saveTours(groupeId, [tour]);

  @override
  Future<void> saveTours(String groupeId, List<Tour> tours) => guardSupabase(() async {
        if (tours.isEmpty) return;
        await _db
            .from('tontine_turns')
            .upsert([for (final tour in tours) tourToRow(groupeId, tour)], onConflict: 'id');
      });

  @override
  Future<void> reorganiserTours(
    String groupeId, {
    required List<Tour> tours,
    required List<Changement> changements,
    required String motif,
  }) =>
      guardSupabase(() async {
        await _db.rpc('reorder_turns', params: {
          'p_group_id': groupeId,
          'p_reason': motif,
          'p_turns': [
            for (final tour in tours)
              {'id': tour.id, 'position': tour.position, 'planned_date': encodeDate(tour.datePrevue)},
          ],
          'p_changes': [
            for (final changement in changements)
              {
                'turn_id': changement.tourId,
                'old_position': changement.anciennePosition,
                'new_position': changement.nouvellePosition,
              },
          ],
        });
      });

  // ---------------------------------------------------------- cotisations

  @override
  String nouvelIdCotisation(String groupeId) => _nouvelId();

  @override
  Future<List<Cotisation>> getCotisations(String groupeId) => guardSupabase(() async {
        final lignes = await _db
            .from('tontine_contributions')
            .select()
            .eq('group_id', groupeId)
            .order('created_at', ascending: true);
        return lignes.map(cotisationFromRow).toList(growable: false);
      });

  @override
  Stream<List<Cotisation>> watchCotisations(String groupeId) =>
      _watch(groupeId, const ['tontine_contributions'], () => getCotisations(groupeId));

  @override
  Future<void> saveCotisation(String groupeId, Cotisation cotisation) => guardSupabase(() async {
        await _db.from('tontine_contributions').insert(cotisationToRow(groupeId, cotisation));
      });

  // --------------------------------------------------------- déclarations

  @override
  String nouvelIdDeclaration(String groupeId) => _nouvelId();

  @override
  Future<List<Declaration>> getDeclarations(String groupeId) => guardSupabase(() async {
        final lignes = await _db
            .from('tontine_declarations')
            .select()
            .eq('group_id', groupeId)
            .order('created_at', ascending: true);
        return lignes.map(declarationFromRow).toList(growable: false);
      });

  @override
  Stream<List<Declaration>> watchDeclarations(String groupeId) =>
      _watch(groupeId, const ['tontine_declarations'], () => getDeclarations(groupeId));

  @override
  Future<void> deposerDeclaration(String groupeId, Declaration declaration) =>
      guardSupabase(() async {
        await _db.from('tontine_declarations').insert(declarationToInsertRow(groupeId, declaration));
      });

  @override
  Future<String> validerDeclaration(
    String groupeId, {
    required String declarationId,
    required int montantDu,
    required int penalite,
  }) =>
      guardSupabase(() async {
        final id = await _db.rpc('validate_declaration', params: {
          'p_declaration_id': declarationId,
          'p_amount_due': montantDu,
          'p_penalty': penalite,
        });
        return id as String;
      });

  @override
  Future<void> contesterDeclaration(
    String groupeId, {
    required String declarationId,
    required String motif,
  }) =>
      guardSupabase(() async {
        await _db.from('tontine_declarations').update({
          'status': 'contestee',
          'dispute_reason': motif,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', declarationId).eq('group_id', groupeId);
      });

  // -------------------------------------------------------------- preuves

  @override
  String nouvelIdPreuve(String groupeId) => _nouvelId();

  @override
  Future<void> savePreuve(String groupeId, Preuve preuve) => guardSupabase(() async {
        final octets = base64Decode(preuve.imageEncodee);
        final chemin = '$groupeId/${preuve.id}.jpg';
        await _stockage.deposer(chemin, octets);
        await _db.from('tontine_proofs').insert({
          'id': preuve.id,
          'group_id': groupeId,
          'storage_path': chemin,
          'size_bytes': octets.lengthInBytes,
        });
      });

  @override
  Future<Preuve?> getPreuve(String groupeId, String preuveId) => guardSupabase(() async {
        final ligne = await _db
            .from('tontine_proofs')
            .select()
            .eq('group_id', groupeId)
            .eq('id', preuveId)
            .maybeSingle();
        if (ligne == null) return null;
        final octets = await _stockage.telecharger(ligne['storage_path'] as String);
        return Preuve(
          id: ligne['id'] as String,
          imageEncodee: base64Encode(octets),
          tailleOctets: decodeInt(ligne['size_bytes']),
          createdAt: decodeTimestamp(ligne['created_at']),
        );
      });

  // ---------------------------------------------------------- changements

  @override
  Future<List<Changement>> getChangements(String groupeId) => guardSupabase(() async {
        final lignes = await _db
            .from('tontine_turn_changes')
            .select()
            .eq('group_id', groupeId)
            .order('created_at', ascending: true);
        return lignes.map(changementFromRow).toList(growable: false);
      });

  @override
  Stream<List<Changement>> watchChangements(String groupeId) =>
      _watch(groupeId, const ['tontine_turn_changes'], () => getChangements(groupeId));
}
