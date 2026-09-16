import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tour.dart';
import '../../auth/application/auth_providers.dart';
import '../../tontine/application/tontine_providers.dart';

/// Programme (tours) de la tontine courante, trié par [Tour.position] et mis
/// à jour en direct. Liste vide tant que la tontine courante n'est pas
/// résolue (voir [currentTontineIdProvider]) ou si l'échéancier n'a pas
/// encore été généré.
final toursProvider = StreamProvider<List<Tour>>((ref) {
  final tontineId = ref.watch(currentTontineIdProvider);
  if (tontineId == null) return Stream.value(const []);
  return ref.watch(tontineRepositoryProvider).watchTours(tontineId);
});
