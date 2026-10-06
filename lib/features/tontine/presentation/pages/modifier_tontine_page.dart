import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/enums/mode_parts.dart';
import '../../../../domain/enums/regle_penalite.dart';
import '../../../../domain/value_objects/regle_periodicite.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../application/modification_tontine_controller.dart';
import '../../application/tontine_providers.dart';
import '../widgets/mode_parts_selector.dart';
import '../widgets/penalite_field.dart';
import '../widgets/periodicite_field.dart';
import '../../../../l10n/domain_labels.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/l10n.dart';

/// Formulaire de modification de la tontine courante : tous les champs
/// restent modifiables tant qu'aucun tour n'a démarré ([toursProvider]).
/// Dès que le premier tour est en cours, la tontine entière passe en
/// lecture seule — modifier quoi que ce soit (montant, nombre de noms,
/// pénalité, fréquence, répartition des parts) invaliderait les montants
/// dus et les tours déjà calculés.
class ModifierTontinePage extends ConsumerStatefulWidget {
  const ModifierTontinePage({super.key});

  @override
  ConsumerState<ModifierTontinePage> createState() => _ModifierTontinePageState();
}

class _ModifierTontinePageState extends ConsumerState<ModifierTontinePage> {
  final _nom = TextEditingController();
  final _montant = TextEditingController();
  final _nombreDeNoms = TextEditingController();
  var _reglePenalite = ReglePenalite.aucune;
  int? _valeurPenalite;
  var _delaiGraceJours = 0;
  var _periodicite = ReglePeriodicite.tousLesNJours(7);
  var _modeParts = ModeParts.montantFixe;
  var _initialise = false;

  @override
  void dispose() {
    _nom.dispose();
    _montant.dispose();
    _nombreDeNoms.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String? _erreur(int nomsExistants) {
    if (_nom.text.trim().length < 2) {
      return context.l10n.createErrorGroupName;
    }
    final montant = int.tryParse(_montant.text);
    if (montant == null || montant <= 0) {
      return context.l10n.createErrorAmount;
    }
    final nombreDeNoms = int.tryParse(_nombreDeNoms.text);
    if (nombreDeNoms == null || nombreDeNoms <= 0) {
      return context.l10n.createErrorNamesCount;
    }
    if (nombreDeNoms < nomsExistants) {
      return context.l10n.editErrorNamesBelowExisting(nomsExistants);
    }
    if (_reglePenalite != ReglePenalite.aucune &&
        (_valeurPenalite == null || _valeurPenalite! <= 0)) {
      return context.l10n.createErrorPenaltyValue;
    }
    if (_delaiGraceJours < 0 || _delaiGraceJours > 30) {
      return context.l10n.createErrorGraceDays;
    }
    return null;
  }

  Future<void> _enregistrer(Tontine tontine, int nomsExistants) async {
    final erreur = _erreur(nomsExistants);
    if (erreur != null) {
      _message(erreur);
      return;
    }
    final misAJour = Tontine(
      id: tontine.id,
      nom: _nom.text.trim(),
      adminUid: tontine.adminUid,
      montantParNom: int.parse(_montant.text),
      nombreDeNoms: int.parse(_nombreDeNoms.text),
      datePremiereEcheance: tontine.datePremiereEcheance,
      periodicite: _periodicite,
      reglePenalite: _reglePenalite,
      delaiGraceJours: _delaiGraceJours,
      valeurPenalite: _reglePenalite == ReglePenalite.aucune ? null : _valeurPenalite,
      modeParts: _modeParts,
      codeInvitation: tontine.codeInvitation,
    );
    try {
      await ref.read(modificationTontineControllerProvider.notifier).modifierTontine(misAJour);
      if (mounted) {
        ref.read(flashMessageProvider.notifier).set(L10n.current.editSuccess);
        context.go(AppRouter.reglagesPath);
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tontineAsync = ref.watch(tontineProvider);
    final noms = ref.watch(nomsProvider).value ?? const [];
    final tours = ref.watch(toursProvider).value ?? const [];
    final tontineDemarree = tours.isNotEmpty;
    final isAdmin = ref.watch(isAdminProvider);
    final lectureSeule = tontineDemarree || !isAdmin;
    final busy = ref.watch(modificationTontineControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.commonBack,
          onPressed: () => context.go(AppRouter.reglagesPath),
        ),
        title: Text(isAdmin ? context.l10n.editTitleAdmin : context.l10n.editTitleMember),
      ),
      body: tontineAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: context.l10n.errorLoadTontine,
          onRetry: () => ref.invalidate(tontineProvider),
        ),
        data: (tontine) {
          if (tontine == null) {
            return ErrorView(message: context.l10n.errorNoTontine);
          }
          if (!_initialise) {
            _nom.text = tontine.nom;
            _montant.text = '${tontine.montantParNom}';
            _nombreDeNoms.text = '${tontine.nombreDeNoms}';
            _reglePenalite = tontine.reglePenalite;
            _valeurPenalite = tontine.valeurPenalite;
            _delaiGraceJours = tontine.delaiGraceJours;
            _periodicite = tontine.periodicite;
            _modeParts = tontine.modeParts;
            _initialise = true;
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: lectureSeule
                    ? _ResumeFige(
                        tontine: tontine,
                        libellePeriodicite: periodiciteLabel(tontine.periodicite, context.l10n),
                        figeeParDemarrage: tontineDemarree,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(context.l10n.fieldGroupName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _nom,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(hintText: context.l10n.fieldGroupNameHint),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(context.l10n.fieldAmountPerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _montant,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              suffixText: AppConstants.currency,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(context.l10n.fieldNamesCount, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _nombreDeNoms,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PenaliteField(
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
                          const SizedBox(height: AppSpacing.lg),
                          PeriodiciteField(
                            initialValue: _periodicite,
                            onChanged: (valeur) => _periodicite = valeur,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(context.l10n.createStepShares, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          ModePartsSelector(
                            value: _modeParts,
                            onChanged: (valeur) => setState(() => _modeParts = valeur),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: context.l10n.editSave,
                            variant: AppButtonVariant.accent,
                            busy: busy,
                            onPressed: busy ? null : () => _enregistrer(tontine, noms.length),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

}

/// Résumé en lecture seule de toute la tontine, affiché dès que le premier
/// tour est en cours (voir la doc de [ModifierTontinePage]) ou consulté par
/// un membre plutôt que l'administratrice — dans ce second cas, les champs
/// resteraient en théorie modifiables si le tour n'a pas démarré, mais seule
/// l'administratrice y est autorisée.
class _ResumeFige extends StatelessWidget {
  const _ResumeFige({
    required this.tontine,
    required this.libellePeriodicite,
    required this.figeeParDemarrage,
  });

  final Tontine tontine;
  final String libellePeriodicite;
  final bool figeeParDemarrage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      color: AppColors.canvas,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.slate),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    figeeParDemarrage
                        ? l10n.editFrozenStarted
                        : l10n.editReadOnlyAdminOnly,
                    style: AppTypography.micro.copyWith(color: AppColors.slate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _ligne(l10n.fieldGroupName, tontine.nom),
            const SizedBox(height: 4),
            _ligne(l10n.fieldAmountPerName, formatAmount(tontine.montantParNom)),
            const SizedBox(height: 4),
            _ligne(l10n.fieldNamesCount, '${tontine.nombreDeNoms}'),
            const SizedBox(height: 4),
            _ligne(l10n.recapPenalty, tontine.reglePenalite.label(l10n)),
            if (tontine.reglePenalite != ReglePenalite.aucune) ...[
              const SizedBox(height: 4),
              _ligne(l10n.recapPenaltyValue, '${tontine.valeurPenalite}'),
              const SizedBox(height: 4),
              _ligne(l10n.recapGraceDays, l10n.recapGraceDaysValue(tontine.delaiGraceJours)),
            ],
            const SizedBox(height: 4),
            _ligne(l10n.fieldFrequency, libellePeriodicite),
            const SizedBox(height: 4),
            _ligne(l10n.createStepShares, tontine.modeParts.label(l10n)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              figeeParDemarrage
                  ? l10n.editFrozenExplanation
                  : l10n.editAdminOnlyExplanation,
              style: AppTypography.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligne(String label, String valeur) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.secondary)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            valeur,
            style: AppTypography.body,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
