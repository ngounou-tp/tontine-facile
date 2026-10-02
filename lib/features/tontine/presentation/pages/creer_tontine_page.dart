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

const _titresEtapes = [
  'Le groupe',
  'Fréquence des échéances',
  'Pénalité et délai de grâce',
  'Répartition des parts',
  'Confirmation',
];

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
      return 'Le nom du groupe doit contenir au moins 2 caractères.';
    }
    if (_nomAdmin.text.trim().isEmpty) {
      return 'Indiquez votre nom complet.';
    }
    final montant = int.tryParse(_montant.text);
    if (montant == null || montant <= 0) {
      return 'Indiquez un montant par nom valide.';
    }
    final nombreDeNoms = int.tryParse(_nombreDeNoms.text);
    if (nombreDeNoms == null || nombreDeNoms <= 0) {
      return 'Indiquez le nombre de noms que comptera la tontine.';
    }
    if (_datePremiereEcheance == null) {
      return 'Choisissez la date de la première échéance.';
    }
    return null;
  }

  String? _erreurEtapePenalite() {
    if (_reglePenalite != ReglePenalite.aucune &&
        (_valeurPenalite == null || _valeurPenalite! <= 0)) {
      return 'Indiquez une valeur de pénalité supérieure à zéro.';
    }
    if (_delaiGraceJours < 0 || _delaiGraceJours > 30) {
      return 'Le délai de grâce doit être compris entre 0 et 30 jours.';
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
    if (_etape == _titresEtapes.length - 1) {
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
        ref.read(flashMessageProvider.notifier).set(
            'Tontine créée avec succès. Ajoutez vos premiers membres.');
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
    final dernierePage = _etape == _titresEtapes.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: _etape > 0 ? 'Étape précédente' : 'Retour',
          onPressed: busy
              ? null
              : (_etape > 0 ? _precedent : () => context.go(AppRouter.choixPath)),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Créer une tontine'),
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
                    'Étape ${_etape + 1} sur ${_titresEtapes.length}',
                    style: AppTypography.micro.copyWith(color: AppColors.slate),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_titresEtapes[_etape], style: AppTypography.screenTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: List.generate(
                      _titresEtapes.length,
                      (index) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index < _titresEtapes.length - 1 ? AppSpacing.xs : 0),
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
                    label: dernierePage ? 'Créer la tontine' : 'Suivant',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nom du groupe', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _nomGroupe,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Tontine des Dames'),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Votre nom complet', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _nomAdmin,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Adèle Tchoumi'),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Montant par nom', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _montant,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '25 000',
            suffixText: 'FCFA',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Nombre de noms', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _nombreDeNoms,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '20'),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Combien de noms (parts) comptera la tontine au total ? Vous les attribuerez '
          'aux membres au fil des inscriptions.',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Date de la première échéance', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        ? 'Choisir une date'
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
    final periodicite = _periodicite;
    final periodiciteLabel = switch (periodicite) {
      RegleTousLesNJours(:final jours) => 'Tous les $jours jours',
      RegleChaqueSemaine(:final jour) => 'Chaque ${jour.libelle.toLowerCase()}',
      RegleToutesLesDeuxSemaines(:final jour) =>
        'Toutes les deux semaines, le ${jour.libelle.toLowerCase()}',
      RegleChaqueMoisJourFixe(:final jour) => 'Chaque mois, le $jour',
      RegleChaqueMoisSemaine(:final occurrence, :final jour) =>
        '${occurrence.libelle} ${jour.libelle.toLowerCase()} du mois',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ligneRecap('Groupe', _nomGroupe.text.trim()),
            _ligneRecap('Administratrice', _nomAdmin.text.trim()),
            _ligneRecap(
              'Montant par nom',
              int.tryParse(_montant.text) == null ? '${_montant.text} FCFA' : formatAmount(int.parse(_montant.text)),
            ),
            _ligneRecap('Nombre de noms', _nombreDeNoms.text),
            _ligneRecap(
              'Première échéance',
              _datePremiereEcheance == null ? '—' : formatDate(_datePremiereEcheance!),
            ),
            _ligneRecap('Fréquence', periodiciteLabel),
            _ligneRecap('Pénalité', libellePenalite(_reglePenalite)),
            if (_reglePenalite != ReglePenalite.aucune)
              _ligneRecap('Valeur de la pénalité', '${_valeurPenalite ?? '—'}'),
            _ligneRecap('Délai de grâce', '$_delaiGraceJours jour(s)'),
            _ligneRecap('Répartition des parts', _modeParts.libelle),
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
