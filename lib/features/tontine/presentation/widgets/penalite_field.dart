import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/enums/regle_penalite.dart';
import '../../../../l10n/domain_labels.dart';
import '../../../../l10n/l10n.dart';

/// Valeur portée par [PenaliteField] : la règle, sa valeur (montant ou
/// pourcentage selon la règle — `null` tant que non renseignée ou que la
/// règle est [ReglePenalite.aucune]) et le délai de grâce en jours.
typedef PenaliteValue = ({
  ReglePenalite regle,
  int? valeurPenalite,
  int delaiGraceJours,
});

/// Sélecteur de la règle de pénalité de retard (`ReglePenalite`), de sa
/// valeur (montant ou pourcentage, masquée si [ReglePenalite.aucune]) et du
/// délai de grâce avant application (voir `ValidationTontine` : 0 à 30
/// jours, et une valeur strictement positive exigée dès qu'une pénalité est
/// active).
///
/// Gère son propre état interne à partir de [initialValue] ; appelle
/// [onChanged] à chaque saisie, même incomplète — la validation finale (avant
/// de passer à l'étape suivante) reste à la charge de l'écran appelant.
class PenaliteField extends StatefulWidget {
  const PenaliteField({required this.initialValue, required this.onChanged, super.key});

  final PenaliteValue initialValue;
  final ValueChanged<PenaliteValue> onChanged;

  @override
  State<PenaliteField> createState() => _PenaliteFieldState();
}

class _PenaliteFieldState extends State<PenaliteField> {
  late ReglePenalite _regle;
  late final TextEditingController _valeurController;
  late final TextEditingController _delaiController;

  @override
  void initState() {
    super.initState();
    _regle = widget.initialValue.regle;
    _valeurController = TextEditingController(
      text: widget.initialValue.valeurPenalite?.toString() ?? '',
    );
    _delaiController = TextEditingController(text: '${widget.initialValue.delaiGraceJours}');
  }

  @override
  void dispose() {
    _valeurController.dispose();
    _delaiController.dispose();
    super.dispose();
  }

  void _emettre() {
    widget.onChanged((
      regle: _regle,
      valeurPenalite: _regle == ReglePenalite.aucune ? null : int.tryParse(_valeurController.text),
      delaiGraceJours: int.tryParse(_delaiController.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.fieldPenaltyRule, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<ReglePenalite>(
          initialValue: _regle,
          isExpanded: true,
          items: [
            for (final r in ReglePenalite.values)
              DropdownMenuItem(
                value: r,
                child: Text(r.label(context.l10n), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (r) {
            if (r == null) return;
            setState(() => _regle = r);
            _emettre();
          },
        ),
        if (_regle != ReglePenalite.aucune) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _regle == ReglePenalite.forfaitaire
                ? context.l10n.fieldPenaltyAmount
                : context.l10n.fieldPenaltyPercent,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _valeurController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _emettre(),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.fieldGraceDays, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _delaiController,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emettre(),
        ),
      ],
    );
  }
}
