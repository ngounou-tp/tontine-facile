class Membre {
  final String id;
  final String nomComplet;
  final String? email;
  final String? whatsapp;
  final String? uid;
  final bool actif;

  /// Code de l'invitation générée pour ce membre (voir
  /// `InscriptionService.inviterMembre`), dénormalisé ici pour rester
  /// consultable depuis sa fiche après la création — l'écran d'ajout ne le
  /// montre qu'une fois, au moment de l'inscription.
  final String? codeInvitation;

  const Membre({
    required this.id,
    required this.nomComplet,
    this.email,
    this.whatsapp,
    this.uid,
    this.actif = true,
    this.codeInvitation,
  });
}