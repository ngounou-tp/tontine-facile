class Membre {
  final String id;
  final String nomComplet;
  final String? email;
  final String? whatsapp;
  final String? uid;
  final bool actif;

  const Membre({
    required this.id,
    required this.nomComplet,
    this.email,
    this.whatsapp,
    this.uid,
    this.actif = true,
  });
}