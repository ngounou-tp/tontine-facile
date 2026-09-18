import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/enums/statut_cotisation.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../cotisations/application/cotisations_providers.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../application/tontine_providers.dart';
import '../widgets/contribution_progress.dart';
import '../widgets/current_tour_card.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/dashboard_summary_card.dart';
import '../widgets/pending_declarations_banner.dart';

/// Tableau de bord de l'administratrice : vue d'ensemble de sa tontine
/// (montant distribué par tour, tour en cours, progression de la collecte,
/// déclarations en attente, membres actifs) et accès rapide à la collecte
/// et à l'ajout d'un membre. Aucune donnée n'est figée en dur : tout vient
/// des providers de la tontine, des noms, des tours et des cotisations
/// courants.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlashMessageListener.attach(ref, context);
    final tontineAsync = ref.watch(tontineProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return AppScaffold(
      selectedNavIndex: 0,
      appBar: AppBar(
        title: Text(tontineAsync.value?.nom ?? 'TontineFacile'),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRouter.reglagesPath),
            tooltip: 'Réglages',
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: !isAdmin
          ? null
          : FloatingActionButton.extended(
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
    final isAdmin = ref.watch(isAdminProvider);
    final membres = ref.watch(membresProvider).value ?? const <Membre>[];
    final noms = ref.watch(nomsProvider).value ?? const [];
    final tours = ref.watch(toursProvider).value ?? const [];
    final tourActuel = ref.watch(tourActuelProvider);
    final totalAttendu = ref.watch(totalAttenduTourActuelProvider);
    final totalCollecte = ref.watch(totalCollecteTourActuelProvider);
    final declarationsEnAttente = ref.watch(declarationsEnAttenteProvider);
    final cotisations = ref.watch(cotisationsProvider).value ?? const [];

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

    final cotisationsValidees =
        cotisations.where((c) => c.statut == StatutCotisation.validee);
    final paiementsATemps = cotisationsValidees.where((c) => c.penalite == 0).length;
    final paiementsEnRetard = cotisationsValidees.where((c) => c.penalite > 0).length;
    final tauxCollecte = tourActuel == null || totalAttendu <= 0
        ? null
        : totalCollecte / totalAttendu;

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
        DashboardStatsGrid(
          membresActifs: actifs,
          nomsAttribues: noms.length,
          nomsAttendus: tontine.nombreDeNoms,
          tauxCollecte: tauxCollecte,
          paiementsATemps: paiementsATemps,
          paiementsEnRetard: paiementsEnRetard,
        ),
        const SizedBox(height: AppSpacing.lg),
        PendingDeclarationsBanner(
          nombre: declarationsEnAttente.length,
          onTap: () => context.go(AppRouter.declarationsPath),
        ),
        if (declarationsEnAttente.isNotEmpty) const SizedBox(height: AppSpacing.lg),
        DashboardSummaryCard(montantParTour: tontine.montantParNom * noms.length),
        const SizedBox(height: AppSpacing.xl),
        Text('Tour en cours', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        CurrentTourCard(
          tour: tourActuel,
          noms: noms,
          membres: membres,
          tourGenere: tours.isNotEmpty,
          onCollecter: !isAdmin || tourActuel == null
              ? null
              : () => context.go('${AppRouter.cotisationsPath}/${tourActuel.id}'),
        ),
        if (tourActuel != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ContributionProgress(collecte: totalCollecte, attendu: totalAttendu),
        ],
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
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(AppRouter.membresPath),
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
        ),
      ],
    );
  }
}
