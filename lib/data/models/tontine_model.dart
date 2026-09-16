import '../../domain/entities/tontine.dart';
import '../../domain/enums/mode_parts.dart';
import '../../domain/enums/regle_penalite.dart';
import '../../domain/value_objects/regle_periodicite.dart';
import 'firestore_codec.dart';

class TontineModel {
  const TontineModel({
    required this.id,
    required this.nom,
    required this.adminUid,
    required this.montantParNom,
    required this.nombreDeNoms,
    required this.datePremiereEcheance,
    required this.periodicite,
    required this.reglePenalite,
    required this.delaiGraceJours,
    required this.valeurPenalite,
    required this.modeParts,
    required this.codeInvitation,
  });

  final String id;
  final String nom;
  final String adminUid;
  final int montantParNom;
  final int nombreDeNoms;
  final DateTime datePremiereEcheance;
  final ReglePeriodicite periodicite;
  final ReglePenalite reglePenalite;
  final int delaiGraceJours;
  final int? valeurPenalite;
  final ModeParts modeParts;
  final String codeInvitation;

  factory TontineModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    final periodicite = data['periodicite'];
    if (periodicite is! Map) {
      throw const FormatException('La périodicité doit être un objet.');
    }
    final regle = data['reglePenalite'];
    final mode = data['modeParts'];
    if (regle is! String || mode is! String) {
      throw const FormatException('Les enums de tontine sont obligatoires.');
    }
    return TontineModel(
      id: id,
      nom: FirestoreCodec.requiredString(data, 'nom'),
      adminUid: FirestoreCodec.requiredString(data, 'adminUid'),
      montantParNom: FirestoreCodec.requiredInt(data, 'montantParNom'),
      nombreDeNoms: FirestoreCodec.requiredInt(data, 'nombreDeNoms'),
      datePremiereEcheance:
          FirestoreCodec.requiredDate(data, 'datePremiereEcheance'),
      periodicite: ReglePeriodicite.fromJson(
        Map<String, dynamic>.from(periodicite),
      ),
      reglePenalite: ReglePenalite.values.byName(regle),
      delaiGraceJours: FirestoreCodec.requiredInt(data, 'delaiGraceJours'),
      valeurPenalite: FirestoreCodec.optionalInt(data, 'valeurPenalite'),
      modeParts: ModeParts.fromId(mode),
      codeInvitation: FirestoreCodec.requiredString(data, 'codeInvitation'),
    );
  }

  factory TontineModel.fromEntity(Tontine entity) => TontineModel(
        id: entity.id,
        nom: entity.nom,
        adminUid: entity.adminUid,
        montantParNom: entity.montantParNom,
        nombreDeNoms: entity.nombreDeNoms,
        datePremiereEcheance: entity.datePremiereEcheance,
        periodicite: entity.periodicite,
        reglePenalite: entity.reglePenalite,
        delaiGraceJours: entity.delaiGraceJours,
        valeurPenalite: entity.valeurPenalite,
        modeParts: entity.modeParts,
        codeInvitation: entity.codeInvitation,
      );

  Tontine toEntity() => Tontine(
        id: id,
        nom: nom,
        adminUid: adminUid,
        montantParNom: montantParNom,
        nombreDeNoms: nombreDeNoms,
        datePremiereEcheance: datePremiereEcheance,
        periodicite: periodicite,
        reglePenalite: reglePenalite,
        delaiGraceJours: delaiGraceJours,
        valeurPenalite: valeurPenalite,
        modeParts: modeParts,
        codeInvitation: codeInvitation,
      );

  Map<String, dynamic> toFirestore() => {
        'nom': nom,
        'adminUid': adminUid,
        'montantParNom': montantParNom,
        'nombreDeNoms': nombreDeNoms,
        'datePremiereEcheance': FirestoreCodec.timestamp(datePremiereEcheance),
        'periodicite': periodicite.toJson(),
        'reglePenalite': reglePenalite.name,
        'delaiGraceJours': delaiGraceJours,
        'valeurPenalite': valeurPenalite,
        'modeParts': modeParts.id,
        'codeInvitation': codeInvitation,
      };
}
