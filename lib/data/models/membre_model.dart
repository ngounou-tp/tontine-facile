import '../../domain/entities/membre.dart';
import 'firestore_codec.dart';

class MembreModel {
  const MembreModel({
    required this.id,
    required this.nomComplet,
    this.email,
    this.whatsapp,
    this.uid,
    this.actif = true,
    this.codeInvitation,
  });

  final String id;
  final String nomComplet;
  final String? email;
  final String? whatsapp;
  final String? uid;
  final bool actif;
  final String? codeInvitation;

  factory MembreModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return MembreModel(
      id: id,
      nomComplet: FirestoreCodec.requiredString(data, 'nomComplet'),
      email: FirestoreCodec.optionalString(data, 'email'),
      whatsapp: FirestoreCodec.optionalString(data, 'whatsapp'),
      uid: FirestoreCodec.optionalString(data, 'uid'),
      actif: data['actif'] == null
          ? true
          : FirestoreCodec.requiredBool(data, 'actif'),
      codeInvitation: FirestoreCodec.optionalString(data, 'codeInvitation'),
    );
  }

  factory MembreModel.fromEntity(Membre entity) => MembreModel(
        id: entity.id,
        nomComplet: entity.nomComplet,
        email: entity.email,
        whatsapp: entity.whatsapp,
        uid: entity.uid,
        actif: entity.actif,
        codeInvitation: entity.codeInvitation,
      );

  Membre toEntity() => Membre(
        id: id,
        nomComplet: nomComplet,
        email: email,
        whatsapp: whatsapp,
        uid: uid,
        actif: actif,
        codeInvitation: codeInvitation,
      );

  Map<String, dynamic> toFirestore() => {
        'nomComplet': nomComplet,
        if (email != null) 'email': email,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (uid != null) 'uid': uid,
        'actif': actif,
        if (codeInvitation != null) 'codeInvitation': codeInvitation,
      };
}
