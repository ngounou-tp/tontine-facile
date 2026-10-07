import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/enums/jour_semaine.dart';
import '../../../../domain/enums/occurrence_mensuelle.dart';
import '../../../../domain/value_objects/regle_periodicite.dart';
import '../../../../l10n/domain_labels.dart';
import '../../../../l10n/l10n.dart';

enum _TypePeriodicite {
  tousLesNJours,
  chaqueSemaine,
  toutesLesDeuxSemaines,
  chaqueMoisJourFixe,
  chaqueMoisSemaine;

  String label(AppLocalizations l10n) => switch (this) {
        tousLesNJours => l10n.periodTypeEveryNDays,
        chaqueSemaine => l10n.periodTypeWeekly,
        toutesLesDeuxSemaines => l10n.periodTypeBiweekly,
        chaqueMoisJourFixe => l10n.periodTypeMonthlyDay,
        chaqueMoisSemaine => l10n.periodTypeMonthlyWeekday,
      };
}

_TypePeriodicite _typeDe(ReglePeriodicite regle) => switch (regle) {
      RegleTousLesNJours() => _TypePeriodicite.tousLesNJours,
      RegleChaqueSemaine() => _TypePeriodicite.chaqueSemaine,
      RegleToutesLesDeuxSemaines() => _TypePeriodicite.toutesLesDeuxSemaines,
      RegleChaqueMoisJourFixe() => _TypePeriodicite.chaqueMoisJourFixe,
      RegleChaqueMoisSemaine() => _TypePeriodicite.chaqueMoisSemaine,
    };

/// Sélecteur de la règle de périodicité des échéances (`ReglePeriodicite`) :
/// choix du type, puis des paramètres propres à ce type.
///
/// Gère son propre état interne (contrôleurs de texte, sélections) à partir
/// de [initialValue] ; n'appelle [onChanged] que lorsque la saisie produit
/// une règle valide — en particulier, ne construit jamais
/// `ReglePeriodicite.tousLesNJours` avec une valeur ≤ 0, ce qui déclencherait
/// l'assertion du constructeur.
class PeriodiciteField extends StatefulWidget {
  const PeriodiciteField({required this.initialValue, required this.onChanged, super.key});

  final ReglePeriodicite initialValue;
  final ValueChanged<ReglePeriodicite> onChanged;

  @override
  State<PeriodiciteField> createState() => _PeriodiciteFieldState();
}

class _PeriodiciteFieldState extends State<PeriodiciteField> {
  late _TypePeriodicite _type;
  late final TextEditingController _joursController;
  late final TextEditingController _jourMoisController;
  late JourSemaine _jourSemaine;
  late OccurrenceMensuelle _occurrence;

  @override
  void initState() {
    super.initState();
    final regle = widget.initialValue;
    _type = _typeDe(regle);
    _joursController = TextEditingController(
      text: regle is RegleTousLesNJours ? '${regle.jours}' : '7',
    );
    _jourMoisController = TextEditingController(
      text: regle is RegleChaqueMoisJourFixe ? '${regle.jour}' : '1',
    );
    _jourSemaine = switch (regle) {
      RegleChaqueSemaine(:final jour) => jour,
      RegleToutesLesDeuxSemaines(:final jour) => jour,
      RegleChaqueMoisSemaine(:final jour) => jour,
      _ => JourSemaine.lundi,
    };
    _occurrence = regle is RegleChaqueMoisSemaine ? regle.occurrence : OccurrenceMensuelle.premier;
  }

  @override
  void dispose() {
    _joursController.dispose();
    _jourMoisController.dispose();
    super.dispose();
  }

  void _emettre() {
    final regle = switch (_type) {
      _TypePeriodicite.tousLesNJours => _tousLesNJours(),
      _TypePeriodicite.chaqueSemaine => ReglePeriodicite.chaqueSemaine(_jourSemaine),
      _TypePeriodicite.toutesLesDeuxSemaines =>
        ReglePeriodicite.toutesLesDeuxSemaines(_jourSemaine),
      _TypePeriodicite.chaqueMoisJourFixe => _chaqueMoisJourFixe(),
      _TypePeriodicite.chaqueMoisSemaine =>
        ReglePeriodicite.chaqueMoisSemaine(_occurrence, _jourSemaine),
    };
    if (regle != null) widget.onChanged(regle);
  }

  ReglePeriodicite? _tousLesNJours() {
    final jours = int.tryParse(_joursController.text);
    if (jours == null || jours <= 0) return null;
    return ReglePeriodicite.tousLesNJours(jours);
  }

  ReglePeriodicite? _chaqueMoisJourFixe() {
    final jour = int.tryParse(_jourMoisController.text);
    if (jour == null || jour < 1 || jour > 31) return null;
    return ReglePeriodicite.chaqueMoisJourFixe(jour);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.fieldFrequency, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<_TypePeriodicite>(
          initialValue: _type,
          isExpanded: true,
          items: [
            for (final t in _TypePeriodicite.values)
              DropdownMenuItem(
                value: t,
                child: Text(t.label(context.l10n), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (t) {
            if (t == null) return;
            setState(() => _type = t);
            _emettre();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ..._champsSpecifiques(),
      ],
    );
  }

  List<Widget> _champsSpecifiques() {
    switch (_type) {
      case _TypePeriodicite.tousLesNJours:
        return [_champEntier(context.l10n.fieldDaysBetweenDueDates, _joursController)];
      case _TypePeriodicite.chaqueSemaine:
      case _TypePeriodicite.toutesLesDeuxSemaines:
        return [_champJourSemaine()];
      case _TypePeriodicite.chaqueMoisJourFixe:
        return [_champEntier(context.l10n.fieldDayOfMonth, _jourMoisController)];
      case _TypePeriodicite.chaqueMoisSemaine:
        return [_champOccurrence(), const SizedBox(height: AppSpacing.md), _champJourSemaine()];
    }
  }

  Widget _champEntier(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emettre(),
        ),
      ],
    );
  }

  Widget _champJourSemaine() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.fieldWeekday, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<JourSemaine>(
          initialValue: _jourSemaine,
          isExpanded: true,
          items: [
            for (final j in JourSemaine.values)
              DropdownMenuItem(
                value: j,
                child: Text(j.label(context.l10n), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (j) {
            if (j == null) return;
            setState(() => _jourSemaine = j);
            _emettre();
          },
        ),
      ],
    );
  }

  Widget _champOccurrence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.fieldOccurrenceInMonth, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<OccurrenceMensuelle>(
          initialValue: _occurrence,
          isExpanded: true,
          items: [
            for (final o in OccurrenceMensuelle.values)
              DropdownMenuItem(
                value: o,
                child: Text(o.label(context.l10n), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (o) {
            if (o == null) return;
            setState(() => _occurrence = o);
            _emettre();
          },
        ),
      ],
    );
  }
}
