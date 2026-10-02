import '../constants/app_constants.dart';

/// Espace insécable : un montant ne doit jamais se couper en fin de ligne
/// (« 25 » sur une ligne, « 000 FCFA » sur la suivante).
const _nbsp = ' ';

/// `25000` → `25 000` (milliers séparés par une espace insécable, usage
/// français). Les montants FCFA sont toujours entiers.
String formatNumber(num value) {
  final negatif = value < 0;
  final chiffres = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) buffer.write(_nbsp);
    buffer.write(chiffres[i]);
  }
  return '${negatif ? '-' : ''}$buffer';
}

/// `25000` → `25 000 FCFA`.
String formatAmount(num amount) => '${formatNumber(amount)}$_nbsp${AppConstants.currency}';
