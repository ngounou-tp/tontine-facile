import '../enums/mode_parts.dart';
import '../enums/regle_penalite.dart';
import '../value_objects/regle_periodicite.dart';

class Tontine {
  final String id;
  final String nom;
  final String adminUid;

  final int montantParNom;

  final DateTime datePremiereEcheance;
  final ReglePeriodicite periodicite;

  final ReglePenalite reglePenalite;
  final int delaiGraceJours;
  final int? valeurPenalite;

  final ModeParts modeParts;

  final String codeInvitation;

  const Tontine({
    required this.id,
    required this.nom,
    required this.adminUid,
    required this.montantParNom,
    required this.datePremiereEcheance,
    required this.periodicite,
    required this.reglePenalite,
    required this.delaiGraceJours,
    required this.valeurPenalite,
    required this.modeParts,
    required this.codeInvitation,
  });
}