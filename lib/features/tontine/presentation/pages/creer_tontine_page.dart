import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/enums/mode_parts.dart';
import '../../../../domain/enums/regle_penalite.dart';
import '../../../../domain/value_objects/regle_periodicite.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../application/creation_tontine_controller.dart';
import '../widgets/mode_parts_selector.dart';
import '../widgets/penalite_field.dart';
import '../widgets/periodicite_field.dart';
import '../../../../l10n/domain_labels.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/l10n.dart';

List<String> _titresEtapes(AppLocalizations l10n) => [
      l10n.createStepGroup,
      l10n.createStepFrequency,
      l10n.createStepPenalty,
      l10n.createStepShares,
      l10n.createStepConfirm,
    ];

const _nombreEtapes = 5;

/// Assistant de création de tontine, en 5 étapes : nom du groupe, montant et
/// première échéance ; périodicité ; pénalité et délai de grâce ; mode de
/// répartition des parts ; confirmation.
///
/// À la création, [CreationTontineController.creerTontine] délègue à
/// `InscriptionService.creerTontinePourAdmin`, qui crée la tontine, le
/// membre de l'administratrice, son invitation auto-réclamée et son profil
/// — voir ce service pour l'orchestration Firestore complète.
class CreerTontinePage extends ConsumerStatefulWidget {
  const CreerTontinePage({super.key});

  @override
  ConsumerState<CreerTontinePage> createState() => _CreerTontinePageState();
}

class _CreerTontinePageState extends ConsumerState<CreerTontinePage> {
  var _etape = 0;

  final _nomGroupe = TextEditingController();
  final _nomAdmin = TextEditingController();
  final _montant = TextEditingController();
  final _nombreDeNoms = TextEditingController();
  DateTime? _datePremiereEcheance;

  ReglePeriodicite _periodicite = ReglePeriodicite.tousLesNJours(7);

  ReglePenalite _reglePenalite = ReglePenalite.aucune;
  int? _valeurPenalite;
  var _delaiGraceJours = 0;

  ModeParts _modeParts = ModeParts.montantFixe;

  @override
  void dispose() {
    _nomGroupe.dispose();
    _nomAdmin.dispose();
    _montant.dispose();
    _nombreDeNoms.dispose();
    super.dispose();
  }

  String? _erreurEtapeGroupe() {
    if (_nomGroupe.text.trim().length < 2) {
      return context.l10n.createErrorGroupName;
    }
    if (_nomAdmin.text.trim().isEmpty) {
      return context.l10n.createErrorFullName;
    }
    final montant = int.tryParse(_montant.text);
    if (montant == null || montant <= 0) {
      return context.l10n.createErrorAmount;
    }
    final nombreDeNoms = int.tryParse(_nombreDeNoms.text);
    if (nombreDeNoms == null || nombreDeNoms <= 0) {
      return context.l10n.createErrorNamesCount;
    }
    if (_datePremiereEcheance == null) {
      return context.l10n.createErrorFirstDueDate;
    }
    return null;
  }

  String? _erreurEtapePenalite() {
    if (_reglePenalite != ReglePenalite.aucune &&
        (_valeurPenalite == null || _valeurPenalite! <= 0)) {
      return context.l10n.createErrorPenaltyValue;
    }
    if (_delaiGraceJours < 0 || _delaiGraceJours > 30) {
      return context.l10n.createErrorGraceDays;
    }
    return null;
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _datePremiereEcheance ?? maintenant,
      firstDate: maintenant,
      lastDate: maintenant.add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _datePremiereEcheance = date);
  }

  Future<void> _suivant() async {
    final erreur = switch (_etape) {
      0 => _erreurEtapeGroupe(),
      2 => _erreurEtapePenalite(),
      _ => null,
    };
    if (erreur != null) {
      _message(erreur);
      return;
    }
    if (_etape == _nombreEtapes - 1) {
      await _creer();
      return;
    }
    setState(() => _etape += 1);
  }

  void _precedent() => setState(() => _etape -= 1);

  Future<void> _creer() async {
    try {
      final tontineSansId = Tontine(
        id: 'ignore',
        nom: _nomGroupe.text.trim(),
        adminUid: 'ignore',
        montantParNom: int.parse(_montant.text),
        nombreDeNoms: int.parse(_nombreDeNoms.text),
        datePremiereEcheance: _datePremiereEcheance!,
        periodicite: _periodicite,
        reglePenalite: _reglePenalite,
        delaiGraceJours: _delaiGraceJours,
        valeurPenalite: _reglePenalite == ReglePenalite.aucune ? null : _valeurPenalite,
        modeParts: _modeParts,
        codeInvitation: 'IGNORE',
      );

      await ref.read(creationTontineControllerProvider.notifier).creerTontine(
            nomCompletAdmin: _nomAdmin.text.trim(),
            tontineSansId: tontineSansId,
          );
      // La tontine et le profil viennent d'être écrits dans Firestore, mais
      // la session/tontine courantes (qui les suivent en direct) peuvent ne
      // pas l'avoir encore répercuté : naviguer tout de suite ferait
      // rebondir le routeur sur /bienvenue, qui traite un profil pas encore
      // propagé comme absent (voir `AppRouter.redirect`). On attend.
      if (ref.read(currentTontineProvider).value == null) {
        await _attendreTontine();
      }
      if (mounted) {
        ref.read(flashMessageProvider.notifier).set(L10n.current.createSuccess);
        context.go(AppRouter.membresPath);
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  /// Attend la prochaine émission de [currentTontineProvider] non nulle
  /// (avec une limite raisonnable pour ne jamais bloquer indéfiniment si la
  /// propagation échoue).
  Future<void> _attendreTontine() async {
    final completeur = Completer<void>();
    final abonnement = ref.listenManual(currentTontineProvider, (_, next) {
      if (next.value != null && !completeur.isCompleted) {
        completeur.complete();
      }
    });
    try {
      await completeur.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
    } finally {
      abonnement.close();
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(creationTontineControllerProvider).isLoading;
    final dernierePage = _etape == _nombreEtapes - 1;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: _etape > 0 ? l10n.createPreviousStep : l10n.commonBack,
          onPressed: busy
              ? null
              : (_etape > 0 ? _precedent : () => context.go(AppRouter.choixPath)),
        ),
        automaticallyImplyLeading: false,
        title: Text(l10n.createTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.createStepOf(_etape + 1, _nombreEtapes),
                    style: AppTypography.micro.copyWith(color: AppColors.slate),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_titresEtapes(l10n)[_etape], style: AppTypography.screenTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: List.generate(
                      _nombreEtapes,
                      (index) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index < _nombreEtapes - 1 ? AppSpacing.xs : 0),
                          height: 8,
                          decoration: BoxDecoration(
                            color: index <= _etape ? AppColors.indigo : AppColors.surface,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _contenuEtape(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: AppButton(
                    label: dernierePage ? l10n.createSubmit : l10n.commonNext,
                    variant: AppButtonVariant.accent,
                    busy: busy,
                    onPressed: busy ? null : _suivant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenuEtape() {
    return switch (_etape) {
      0 => _etapeGroupe(),
      1 => PeriodiciteField(
          initialValue: _periodicite,
          onChanged: (regle) => _periodicite = regle,
        ),
      2 => PenaliteField(
          initialValue: (
            regle: _reglePenalite,
            valeurPenalite: _valeurPenalite,
            delaiGraceJours: _delaiGraceJours,
          ),
          onChanged: (valeur) {
            _reglePenalite = valeur.regle;
            _valeurPenalite = valeur.valeurPenalite;
            _delaiGraceJours = valeur.delaiGraceJours;
          },
        ),
      3 => ModePartsSelector(
          value: _modeParts,
          onChanged: (mode) => setState(() => _modeParts = mode),
        ),
      _ => _etapeConfirmation(),
    };
  }

  Widget _etapeGroupe() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.fieldGroupName, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _nomGroupe,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l10n.fieldGroupNameHint),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.fieldYourFullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _nomAdmin,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l10n.fieldFullNameHint),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.fieldAmountPerName, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _montant,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: l10n.fieldAmountHint,
            suffixText: AppConstants.currency,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.fieldNamesCount, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _nombreDeNoms,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '20'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.fieldNamesCountHelp,
          style: AppTypography.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.fieldFirstDueDate, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          onTap: _choisirDate,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.slate, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _datePremiereEcheance == null
                        ? l10n.fieldChooseDate
                        : formatDate(_datePremiereEcheance!),
                    style: _datePremiereEcheance == null
                        ? AppTypography.body.copyWith(color: AppColors.slate)
                        : AppTypography.body,
                  ),
                ),
                const Icon(Icons.expand_more, color: AppColors.slate),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _etapeConfirmation() {
    final l10n = context.l10n;
    final libellePeriodicite = periodiciteLabel(_periodicite, l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ligneRecap(l10n.recapGroup, _nomGroupe.text.trim()),
            _ligneRecap(l10n.recapAdmin, _nomAdmin.text.trim()),
            _ligneRecap(
              l10n.fieldAmountPerName,
              int.tryParse(_montant.text) == null ? '${_montant.text} ${AppConstants.currency}' : formatAmount(int.parse(_montant.text)),
            ),
            _ligneRecap(l10n.fieldNamesCount, _nombreDeNoms.text),
            _ligneRecap(
              l10n.recapFirstDueDate,
              _datePremiereEcheance == null ? '—' : formatDate(_datePremiereEcheance!),
            ),
            _ligneRecap(l10n.fieldFrequency, libellePeriodicite),
            _ligneRecap(l10n.recapPenalty, _reglePenalite.label(l10n)),
            if (_reglePenalite != ReglePenalite.aucune)
              _ligneRecap(l10n.recapPenaltyValue, '${_valeurPenalite ?? '—'}'),
            _ligneRecap(l10n.recapGraceDays, l10n.recapGraceDaysValue(_delaiGraceJours)),
            _ligneRecap(l10n.createStepShares, _modeParts.label(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _ligneRecap(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTypography.secondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(valeur, textAlign: TextAlign.right, style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}
