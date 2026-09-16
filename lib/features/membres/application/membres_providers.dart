import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/membre.dart';
import '../../../domain/entities/nom.dart';
import '../../auth/application/auth_providers.dart';
import '../../tontine/application/tontine_providers.dart';

/// Membres de la tontine courante, mis à jour en direct.
///
/// Liste vide tant que la session n'est pas résolue ou que le compte n'a pas
/// de profil (voir [currentTontineIdProvider]) — inclut les membres inactifs
/// et les placeholders non encore réclamés (`uid == null`) ; filtrez côté UI
/// selon le besoin de l'écran.
final membresProvider = StreamProvider<List<Membre>>((ref) {
  final tontineId = ref.watch(currentTontineIdProvider);
  if (tontineId == null) return Stream.value(const []);
  return ref.watch(tontineRepositoryProvider).watchMembres(tontineId);
});

/// Noms (parts/tours de la tontine) et leurs détenteurs de part, mis à jour
/// en direct. Liste vide tant que la tontine courante n'est pas résolue.
final nomsProvider = StreamProvider<List<Nom>>((ref) {
  final tontineId = ref.watch(currentTontineIdProvider);
  if (tontineId == null) return Stream.value(const []);
  return ref.watch(tontineRepositoryProvider).watchNoms(tontineId);
});
