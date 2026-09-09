class Changement {
  final String id;
  final String tourId;
  final int anciennePosition;
  final int nouvellePosition;
  final String motif;
  final String auteurUid;
  final DateTime createdAt;

  const Changement({
    required this.id,
    required this.tourId,
    required this.anciennePosition,
    required this.nouvellePosition,
    required this.motif,
    required this.auteurUid,
    required this.createdAt,
  });
}