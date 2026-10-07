import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import 'penalite_exception_dialog.dart';
import 'preuve_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/l10n.dart';

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
      setState(() => _erreur = context.l10n.contribInvalidAmount);
      return;
    }
    if (montant > widget.montantDu) {
      setState(() => _erreur = context.l10n.contribAmountExceedsDue);
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
        : (exonerer ? context.l10n.contribMarkedOnTimeReason : null);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.contribAmountDue(formatAmount(widget.montantDu)), style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.contribAmountPaid, style: AppTypography.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
        // Le montant est LA donnée de l'écran : saisie en grands chiffres,
        // clavier numérique, chiffres seuls (ni espace, ni virgule).
        TextFormField(
          controller: _montant,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.amountXl.copyWith(fontSize: 28),
          decoration: InputDecoration(
            suffixText: AppConstants.currency,
            suffixStyle: AppTypography.bodyStrong.copyWith(color: AppColors.slate),
            errorText: _erreur,
          ),
          onChanged: (_) {
            if (_erreur != null) setState(() => _erreur = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.contribPaymentDate, style: AppTypography.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          onTap: _choisirDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.indigo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(formatDate(_datePaiement), style: AppTypography.body)),
                Text(formatEcheanceRelative(_datePaiement), style: AppTypography.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.contribIsLate, style: AppTypography.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(context.l10n.contribOnTime)),
            ButtonSegment(value: true, label: Text(context.l10n.statusLate)),
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
        // La section pénalité se déplie au lieu d'apparaître d'un coup :
        // l'œil suit ce qui vient de s'ajouter sous le choix « En retard ».
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.easeOut,
          alignment: Alignment.topCenter,
          child: !_paiementEnRetard
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _exonererPenalite ? AppColors.canvas : AppColors.warning.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _exonererPenalite ? context.l10n.contribPenaltyWaived : context.l10n.contribPenaltyComputed,
                                style: AppTypography.bodyStrong,
                              ),
                            ),
                            Text(
                              formatAmount(_penaliteCalculee),
                              style: AppTypography.amountInline.copyWith(
                                color: _exonererPenalite ? AppColors.slate : AppColors.warningInk,
                                decoration: _exonererPenalite ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                        if (_exonererPenalite && _motifException != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(_motifException!, style: AppTypography.secondary),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => _basculerExoneration(!_exonererPenalite),
                            child: Text(_exonererPenalite ? context.l10n.contribCancelWaiver : context.l10n.contribWaivePenalty),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        PreuvePicker(value: _preuve, onChanged: (valeur) => setState(() => _preuve = valeur)),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: context.l10n.contribSubmit,
          variant: AppButtonVariant.accent,
          busy: widget.busy,
          onPressed: widget.busy ? null : _soumettre,
        ),
      ],
    );
  }
}
