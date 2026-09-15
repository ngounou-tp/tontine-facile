/// Invitation nominative : `invitations/{code}`.
///
/// Générée par l'administratrice pour un membre placeholder précis
/// (`membreId`, créé sans `uid`). Le code, remis au futur membre, permet à
/// n'importe quel utilisateur connecté de retrouver la tontine et le membre
/// à réclamer sans avoir besoin d'en être déjà membre.
///
/// [nomTontine] et [nombreMembres] sont un instantané dénormalisé de la
/// tontine au moment de l'invitation : les règles Firestore autorisent la
/// lecture de ce document sans authentification (contrairement à
/// `tontines/{id}`), afin que l'écran d'adhésion puisse prévisualiser la
/// tontine avant même la création d'un compte. Le nombre de membres peut donc
/// être légèrement daté ; ce n'est qu'un aperçu.
class Invitation {
  final String code;
  final String tontineId;
  final String membreId;
  final String nomTontine;
  final int nombreMembres;

  const Invitation({
    required this.code,
    required this.tontineId,
    required this.membreId,
    required this.nomTontine,
    required this.nombreMembres,
  });
}
