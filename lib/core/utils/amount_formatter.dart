import '../../l10n/l10n.dart';
import '../constants/app_constants.dart';

/// Espace insécable : un montant ne doit jamais se couper en fin de ligne
/// (« 25 » sur une ligne, « 000 FCFA » sur la suivante).
const _nbsp = ' ';

/// `25000` → `25 000` en français (espace insécable), `25,000` en anglais.
/// Les montants FCFA sont toujours entiers.
String formatNumber(num value) {
  final separateur = L10n.current.localeName == 'en' ? ',' : _nbsp;
  final negatif = value < 0;
  final chiffres = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    if (i > 0 && (chiffres.length - i) % 3 == 0) buffer.write(separateur);
    buffer.write(chiffres[i]);
  }
  return '${negatif ? '-' : ''}$buffer';
}

/// `25000` → `25 000 FCFA`.
String formatAmount(num amount) => '${formatNumber(amount)}$_nbsp${AppConstants.currency}';
