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
      return 'Le nom du groupe doit contenir au moins 2 caractères.';
    }
    final montant = int.tryParse(_montant.text);
    if (montant == null || montant <= 0) {
      return 'Indiquez un montant par nom valide.';
    }
    final nombreDeNoms = int.tryParse(_nombreDeNoms.text);
    if (nombreDeNoms == null || nombreDeNoms <= 0) {
      return 'Indiquez le nombre de noms que comptera la tontine.';
    }
    if (nombreDeNoms < nomsExistants) {
      return '$nomsExistants nom(s) existent déjà : le nombre de noms ne peut pas '
          'être réduit en dessous de ce total.';
    }
    if (_reglePenalite != ReglePenalite.aucune &&
        (_valeurPenalite == null || _valeurPenalite! <= 0)) {
      return 'Indiquez une valeur de pénalité supérieure à zéro.';
    }
    if (_delaiGraceJours < 0 || _delaiGraceJours > 30) {
      return 'Le délai de grâce doit être compris entre 0 et 30 jours.';
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
        ref.read(flashMessageProvider.notifier).set('Tontine mise à jour.');
        context.go(AppRouter.reglagesPath);
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  String _libellePeriodicite(ReglePeriodicite regle) => switch (regle) {
        RegleTousLesNJours(:final jours) => 'Tous les $jours jours',
        RegleChaqueSemaine(:final jour) => 'Chaque ${jour.libelle.toLowerCase()}',
        RegleToutesLesDeuxSemaines(:final jour) =>
          'Toutes les deux semaines, le ${jour.libelle.toLowerCase()}',
        RegleChaqueMoisJourFixe(:final jour) => 'Chaque mois, le $jour',
        RegleChaqueMoisSemaine(:final occurrence, :final jour) =>
          '${occurrence.libelle} ${jour.libelle.toLowerCase()} du mois',
      };

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
          tooltip: 'Retour',
          onPressed: () => context.go(AppRouter.reglagesPath),
        ),
        title: Text(isAdmin ? 'Modifier la tontine' : 'Réglages de la tontine'),
      ),
      body: tontineAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'Impossible de charger la tontine.',
          onRetry: () => ref.invalidate(tontineProvider),
        ),
        data: (tontine) {
          if (tontine == null) {
            return const ErrorView(message: 'Aucune tontine associée à ce compte.');
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
                        libellePeriodicite: _libellePeriodicite(tontine.periodicite),
                        figeeParDemarrage: tontineDemarree,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Nom du groupe', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _nom,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(hintText: 'Tontine des Dames'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text('Montant par nom', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _montant,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              suffixText: 'FCFA',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text('Nombre de noms', style: TextStyle(fontWeight: FontWeight.w600)),
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
                          const Text('Répartition des parts', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          ModePartsSelector(
                            value: _modeParts,
                            onChanged: (valeur) => setState(() => _modeParts = valeur),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: 'Enregistrer les modifications',
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
                        ? 'Figée — l\'échéancier a démarré'
                        : 'Lecture seule — réservé à l\'administratrice',
                    style: AppTypography.micro.copyWith(color: AppColors.slate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _ligne('Nom du groupe', tontine.nom),
            const SizedBox(height: 4),
            _ligne('Montant par nom', formatAmount(tontine.montantParNom)),
            const SizedBox(height: 4),
            _ligne('Nombre de noms', '${tontine.nombreDeNoms}'),
            const SizedBox(height: 4),
            _ligne('Pénalité', libellePenalite(tontine.reglePenalite)),
            if (tontine.reglePenalite != ReglePenalite.aucune) ...[
              const SizedBox(height: 4),
              _ligne('Valeur de la pénalité', '${tontine.valeurPenalite}'),
              const SizedBox(height: 4),
              _ligne('Délai de grâce', '${tontine.delaiGraceJours} jour(s)'),
            ],
            const SizedBox(height: 4),
            _ligne('Fréquence', libellePeriodicite),
            const SizedBox(height: 4),
            _ligne('Répartition des parts', tontine.modeParts.libelle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              figeeParDemarrage
                  ? 'Toute modification invaliderait les montants dus et les tours '
                      'déjà calculés. Ces informations ne peuvent plus changer une fois '
                      'la collecte commencée.'
                  : "Seule l'administratrice de la tontine peut modifier ces "
                      'informations.',
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
