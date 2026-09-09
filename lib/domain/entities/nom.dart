import 'part.dart';
class Nom {
  final String id;
  final int position;
  final String libelle;
  final List<Part> parts;

  const Nom({
    required this.id,
    required this.position,
    required this.libelle,
    required this.parts,
  });
}