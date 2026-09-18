import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import 'penalite_exception_dialog.dart';
import 'preuve_picker.dart';

/// Valeur soumise par [CotisationForm] : montant réellement versé, date du
/// paiement, pénalité retenue (0 si levée), motif de l'exception le cas
/// échéant, et preuve optionnelle déjà compressée.
typedef CotisationFormValue = ({
  int montantVerse,
  DateTime datePaiement,
  bool exonererPenalite,
  String? motifException,
  Uint8List? preuve,
});

/// Formulaire de saisie d'une cotisation officielle par l'administratrice :
/// montant (pré-rempli au montant dû, modifiable pour un paiement partiel),
/// date de paiement, pénalité calculée en direct à partir de cette date
/// (via [calculerPenalite], injecté pour garder le calcul métier hors de la
/// vue), et possibilité de la lever avec un motif.
class CotisationForm extends StatefulWidget {
  const CotisationForm({
    required this.montantDu,
    required this.calculerPenalite,
    required this.onSubmit,
    this.busy = false,
    this.datePaiementInitiale,
    super.key,
  });

  final int montantDu;
  final int Function(DateTime datePaiement) calculerPenalite;
  final void Function(CotisationFormValue valeur) onSubmit;
  final bool busy;
  final DateTime? datePaiementInitiale;

  @override
  State<CotisationForm> createState() => _CotisationFormState();
}

class _CotisationFormState extends State<CotisationForm> {
  late final TextEditingController _montant;
  late DateTime _datePaiement;
  Uint8List? _preuve;
  late bool _paiementEnRetard;
  var _exonererPenalite = false;
  String? _motifException;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _montant = TextEditingController(text: '${widget.montantDu}');
    _datePaiement = widget.datePaiementInitiale ?? DateTime.now();
    // Pré-coché si la date choisie donne déjà une pénalité non nulle, mais
    // l'administratrice tranche : c'est ce choix, pas seulement la date, qui
    // détermine si la section pénalité s'affiche.
    _paiementEnRetard = widget.calculerPenalite(_datePaiement) > 0;
  }

  @override
  void dispose() {
    _montant.dispose();
    super.dispose();
  }

  int get _penaliteCalculee =>
      _exonererPenalite ? 0 : widget.calculerPenalite(_datePaiement);

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _datePaiement,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    setState(() {
      _datePaiement = date;
      _paiementEnRetard = widget.calculerPenalite(date) > 0;
    });
  }

  Future<void> _basculerExoneration(bool valeur) async {
    if (!valeur) {
      setState(() {
        _exonererPenalite = false;
        _motifException = null;
      });
      return;
    }
    final motif = await demanderMotifExonerationPenalite(context);
    if (motif == null) return;
    setState(() {
      _exonererPenalite = true;
      _motifException = motif;
    });
  }

  void _soumettre() {
    final montant = int.tryParse(_montant.text);
    if (montant == null || montant <= 0) {
      setState(() => _erreur = 'Indiquez un montant versé valide.');
      return;
    }
    if (montant > widget.montantDu) {
      setState(() => _erreur = 'Le montant versé ne peut pas dépasser le montant dû.');
      return;
    }
    setState(() => _erreur = null);

    // Le calcul métier peut donner une pénalité non nulle pour cette date,
    // mais si l'administratrice a explicitement indiqué que ce paiement
    // n'est pas en retard, cela équivaut à lever la pénalité — avec un motif
    // généré automatiquement, sans lui imposer une saisie pour le cas normal
    // (paiement réellement à temps, pénalité déjà nulle).
    final exonerer = _exonererPenalite ||
        (!_paiementEnRetard && widget.calculerPenalite(_datePaiement) > 0);
    final motif = _exonererPenalite
        ? _motifException
        : (exonerer ? 'Marqué comme à temps par l’administratrice.' : null);

    widget.onSubmit((
      montantVerse: montant,
      datePaiement: _datePaiement,
      exonererPenalite: exonerer,
      motifException: motif,
      preuve: _preuve,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${_datePaiement.day.toString().padLeft(2, '0')}/${_datePaiement.month.toString().padLeft(2, '0')}/${_datePaiement.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Montant dû : ${widget.montantDu} FCFA', style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.md),
        const Text('Montant versé', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _montant,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: 'FCFA', errorText: _erreur),
          onChanged: (_) {
            if (_erreur != null) setState(() => _erreur = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Date du paiement', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          onTap: _choisirDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatted, style: AppTypography.body),
                const Icon(Icons.calendar_month_outlined, color: AppColors.slate),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Ce paiement est-il en retard ?', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('À temps')),
            ButtonSegment(value: true, label: Text('En retard')),
          ],
          selected: {_paiementEnRetard},
          onSelectionChanged: (selection) => setState(() {
            _paiementEnRetard = selection.first;
            if (!_paiementEnRetard) {
              _exonererPenalite = false;
              _motifException = null;
            }
          }),
        ),
        if (_paiementEnRetard) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _exonererPenalite ? 'Pénalité levée' : 'Pénalité calculée',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('$_penaliteCalculee FCFA', style: AppTypography.body),
                  ],
                ),
                if (_exonererPenalite && _motifException != null) ...[
                  const SizedBox(height: 4),
                  Text(_motifException!, style: AppTypography.secondary),
                ],
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _basculerExoneration(!_exonererPenalite),
                    child: Text(_exonererPenalite ? 'Annuler la levée' : 'Lever la pénalité'),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PreuvePicker(value: _preuve, onChanged: (valeur) => setState(() => _preuve = valeur)),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Enregistrer la cotisation',
          variant: AppButtonVariant.accent,
          busy: widget.busy,
          onPressed: widget.busy ? null : _soumettre,
        ),
      ],
    );
  }
}
