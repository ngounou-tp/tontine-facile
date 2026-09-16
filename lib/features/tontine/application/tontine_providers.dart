import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tontine.dart';
import '../../auth/application/auth_providers.dart';

/// Identifiant de la tontine de la session courante, ou `null` tant que la
/// session n'est pas résolue ou que le compte n'a pas encore de profil.
///
/// Point d'entrée partagé par [tontineProvider] et par les providers des
/// features `membres`/`echeancier`, qui n'ont besoin que de cet id pour
/// construire leurs propres flux.
final currentTontineIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider).value?.profil?.tontineId;
});

/// Tontine courante, mise à jour en direct (Firestore `.snapshots()`).
///
/// `null` tant que la session n'est pas résolue, que le compte n'a pas de
/// profil, ou si le document n'existe plus.
final tontineProvider = StreamProvider<Tontine?>((ref) {
  final tontineId = ref.watch(currentTontineIdProvider);
  if (tontineId == null) return Stream.value(null);
  return ref.watch(tontineRepositoryProvider).watchTontine(tontineId);
});
