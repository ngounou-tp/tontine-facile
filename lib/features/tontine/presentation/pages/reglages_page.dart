import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/enums/regle_penalite.dart';
import '../../../../domain/value_objects/regle_periodicite.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/tontine_providers.dart';
import '../widgets/penalite_field.dart' show libellePenalite;

/// Onglet Réglages : récapitulatif en lecture seule de la tontine (les
/// règles sont immuables une fois créées, voir `ValidationTontine` /
/// `CreerTontinePage`) et actions de compte.
class ReglagesPage extends ConsumerWidget {
  const ReglagesPage({super.key});

  String _libellePeriodicite(ReglePeriodicite regle) => switch (regle) {
        RegleTousLesNJours(:final jours) => 'Tous les $jours jours',
        RegleChaqueSemaine(:final jour) => 'Chaque ${jour.libelle.toLowerCase()}',
        RegleToutesLesDeuxSemaines(:final jour) =>
          'Toutes les deux semaines, le ${jour.libelle.toLowerCase()}',
        RegleChaqueMoisJourFixe(:final jour) => 'Chaque mois, le $jour',
        RegleChaqueMoisSemaine(:final occurrence, :final jour) =>
          '${occurrence.libelle} ${jour.libelle.toLowerCase()} du mois',
      };

  Future<void> _copierCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tontineAsync = ref.watch(tontineProvider);

    return AppScaffold(
      selectedNavIndex: 3,
      appBar: AppBar(title: const Text('Réglages')),
      body: tontineAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => const Center(child: Text('Impossible de charger la tontine.')),
        data: (tontine) => tontine == null
            ? const Center(child: Text('Aucune tontine associée à ce compte.'))
            : _Contenu(tontine: tontine, formatterPeriodicite: _libellePeriodicite, onCopier: _copierCode),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.tontine,
    required this.formatterPeriodicite,
    required this.onCopier,
  });

  final Tontine tontine;
  final String Function(ReglePeriodicite) formatterPeriodicite;
  final Future<void> Function(BuildContext, String) onCopier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(authControllerProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Votre tontine', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _ligne('Nom', tontine.nom),
                    _ligne('Montant par nom', '${tontine.montantParNom} FCFA'),
                    _ligne('Fréquence', formatterPeriodicite(tontine.periodicite)),
                    _ligne('Pénalité', libellePenalite(tontine.reglePenalite)),
                    if (tontine.reglePenalite != ReglePenalite.aucune)
                      _ligne('Valeur de la pénalité', '${tontine.valeurPenalite ?? '—'}'),
                    _ligne('Délai de grâce', '${tontine.delaiGraceJours} jour(s)'),
                    _ligne('Répartition des parts', tontine.modeParts.libelle, dernier: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Ces règles sont figées après la création de la tontine et ne peuvent plus être modifiées.',
              style: AppTypography.micro,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Code d\'invitation', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tontine.codeInvitation,
                        style: AppTypography.screenTitle.copyWith(letterSpacing: 4),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copier le code',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () => onCopier(context, tontine.codeInvitation),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Se déconnecter',
              variant: AppButtonVariant.destructive,
              busy: busy,
              onPressed: busy ? null : () => ref.read(authControllerProvider.notifier).deconnecter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligne(String label, String valeur, {bool dernier = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: dernier ? 0 : AppSpacing.sm),
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
