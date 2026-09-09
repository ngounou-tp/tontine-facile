import '../../domain/entities/tontine.dart';

abstract interface class TontineRepository {
  Future<List<Tontine>> getTontines();
}