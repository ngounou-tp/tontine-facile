import '../entities/preuve.dart';

class ValidationPreuve {
  const ValidationPreuve();

  static const tailleMaxOctets = 150000;

  void valider(Preuve preuve) {
    if (preuve.imageEncodee.trim().isEmpty) {
      throw ArgumentError('La preuve doit contenir une image encodée.');
    }
    if (preuve.tailleOctets <= 0 || preuve.tailleOctets >= tailleMaxOctets) {
      throw ArgumentError('La preuve doit être inférieure à 150 000 octets.');
    }
  }
}