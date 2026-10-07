import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Signal « quelque chose a changé » sur une table, pour un filtre
/// `colonne = valeur` (en pratique : les lignes d'un groupe). Les
/// repositories rechargent alors les données concernées.
///
/// Séparé de l'accès aux données pour que celui-ci reste testable contre
/// une simple API PostgREST, sans le serveur temps réel.
abstract interface class TableChanges {
  Stream<void> watch(String table, {required String column, required String value});
}

/// Implémentation Supabase Realtime (`postgres_changes`, filtrée par la
/// RLS côté serveur : on ne reçoit que les lignes qu'on a le droit de lire).
class SupabaseTableChanges implements TableChanges {
  SupabaseTableChanges(this._client);

  final SupabaseClient _client;
  static var _compteur = 0;

  @override
  Stream<void> watch(String table, {required String column, required String value}) {
    late final StreamController<void> controleur;
    RealtimeChannel? canal;
    controleur = StreamController<void>.broadcast(
      onListen: () {
        canal = _client
            .channel('changes:$table:$column:$value:${_compteur++}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: column,
                value: value,
              ),
              callback: (_) => controleur.add(null),
            )
            .subscribe();
      },
      onCancel: () async {
        final actif = canal;
        canal = null;
        if (actif != null) await _client.removeChannel(actif);
      },
    );
    return controleur.stream;
  }
}

/// Aucun temps réel : les écrans ne se mettent à jour qu'au rechargement.
/// Utilisé par les tests d'intégration contre PostgREST seul.
class NoTableChanges implements TableChanges {
  const NoTableChanges();

  @override
  Stream<void> watch(String table, {required String column, required String value}) =>
      const Stream.empty();
}
