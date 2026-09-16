import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/enums/statut_tour.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../application/tontine_providers.dart';

/// Tableau de bord de l'administratrice : vue d'ensemble de sa tontine
/// (montant distribué par tour, prochaine échéance, membres actifs) et accès
/// rapide à l'ajout d'un membre.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tontineAsync = ref.watch(tontineProvider);

    return AppScaffold(
      selectedNavIndex: 0,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(tontineAsync.value?.nom ?? 'TontineFacile'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRouter.reglagesPath),
            tooltip: 'Réglages',
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('${AppRouter.membresPath}/ajouter'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: tontineAsync.when(
        loading: () => const LoadingView(message: 'Chargement de votre tontine…'),
        error: (_, _) => ErrorView(
          message: 'Impossible de charger votre tontine.',
          onRetry: () => ref.invalidate(tontineProvider),
        ),
        data: (tontine) => tontine == null
            ? const ErrorView(message: 'Aucune tontine associée à ce compte.')
            : _Contenu(tontine: tontine),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.tontine});

  final Tontine tontine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final membres = ref.watch(membresProvider).value ?? const <Membre>[];
    final noms = ref.watch(nomsProvider).value ?? const <Nom>[];
    final tours = ref.watch(toursProvider).value ?? const <Tour>[];

    Membre? moi;
    final membreId = session?.profil?.membreId;
    if (membreId != null) {
      for (final candidat in membres) {
        if (candidat.id == membreId) {
          moi = candidat;
          break;
        }
      }
    }
    final prenom = moi != null ? moi.nomComplet.split(' ').first : '';
    final actifs = membres.where((m) => m.actif).length;

    Tour? prochainTour;
    for (final tour in [...tours]..sort((a, b) => a.position.compareTo(b.position))) {
      if (tour.statut != StatutTour.remis) {
        prochainTour = tour;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
      children: [
        Text(
          prenom.isEmpty ? 'Bonjour' : 'Bonjour, $prenom',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Voici le résumé de votre tontine.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        _SummaryCard(montantParTour: tontine.montantParNom * noms.length),
        const SizedBox(height: AppSpacing.xl),
        Text('Prochaine échéance', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _EcheanceCard(tour: prochainTour, noms: noms, membres: membres, tourGenere: tours.isNotEmpty),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Membres', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => context.go(AppRouter.membresPath),
              child: const Text('Voir tous'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.canvas,
                  child: Icon(Icons.groups_rounded, color: AppColors.indigo),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    actifs == 0
                        ? 'Aucun membre actif pour le moment'
                        : '$actifs membre${actifs > 1 ? 's' : ''} actif${actifs > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.slate),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.montantParTour});

  final int montantParTour;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distribué par tour', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('$montantParTour FCFA', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.surface)),
                ],
              ),
            ),
            const CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.savings_outlined, color: AppColors.ink, size: 28)),
          ],
        ),
      ),
    );
  }
}

class _EcheanceCard extends StatelessWidget {
  const _EcheanceCard({
    required this.tour,
    required this.noms,
    required this.membres,
    required this.tourGenere,
  });

  final Tour? tour;
  final List<Nom> noms;
  final List<Membre> membres;
  final bool tourGenere;

  String _libelleNom(String nomId) {
    for (final nom in noms) {
      if (nom.id == nomId) return nom.libelle;
    }
    return 'Nom inconnu';
  }

  @override
  Widget build(BuildContext context) {
    if (!tourGenere) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.event_busy_outlined, color: AppColors.slate),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  "L'échéancier n'a pas encore été généré. Attribuez les noms puis générez-le depuis Membres.",
                  style: AppTypography.secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (tour == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Tous les tours ont été remis. Bravo !', style: AppTypography.body),
        ),
      );
    }
    final date = tour!.datePrevue;
    final formatted = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.canvas,
              child: Text('${tour!.position}', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_libelleNom(tour!.nomId), style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Prévu le $formatted', style: AppTypography.secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
