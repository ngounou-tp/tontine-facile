import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/enums/statut_cotisation.dart';
import '../../../../domain/enums/statut_tour.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/member_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../cotisations/application/cotisations_providers.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../application/tontine_providers.dart';
import '../widgets/current_tour_card.dart';
import '../widgets/dashboard_stats_grid.dart';
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
              elevation: 2,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              // « Ajouter » seul ne dit pas quoi : sur l'accueil, l'action
              // n'a pas de contexte implicite.
              label: const Text('Ajouter un membre'),
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
    final membresActifs = membres.where((m) => m.actif).toList(growable: false);
    final actifs = membresActifs.length;

    final cotisationsValidees =
        cotisations.where((c) => c.statut == StatutCotisation.validee);
    final paiementsATemps = cotisationsValidees.where((c) => c.penalite == 0).length;
    final paiementsEnRetard = cotisationsValidees.where((c) => c.penalite > 0).length;
    final toursRemis = tours.where((t) => t.statut == StatutTour.remis).length;

    return ListView(
      // Marge basse élargie pour l'administratrice : le bouton flottant
      // « Ajouter un membre » ne doit pas masquer la dernière carte.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        isAdmin ? 96 : AppSpacing.xl,
      ),
      children: [
        Text(
          prenom.isEmpty ? 'Bonjour' : 'Bonjour, $prenom',
          style: AppTypography.screenTitle,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          isAdmin ? _sousTitre(declarationsEnAttente.length) : 'Voici le résumé de votre tontine.',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        CurrentTourCard(
          tour: tourActuel,
          noms: noms,
          membres: membres,
          tourGenere: tours.isNotEmpty,
          totalCollecte: totalCollecte,
          totalAttendu: totalAttendu,
          onCollecter: !isAdmin || tourActuel == null
              ? null
              : () => context.go('${AppRouter.cotisationsPath}/${tourActuel.id}'),
          onPreparer: isAdmin ? () => context.go(AppRouter.membresPath) : null,
        ),
        PendingDeclarationsBanner(
          nombre: declarationsEnAttente.length,
          onTap: () => context.go(AppRouter.declarationsPath),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: "En un coup d'œil"),
        DashboardStatsGrid(
          membresActifs: actifs,
          nomsAttribues: noms.length,
          nomsAttendus: tontine.nombreDeNoms,
          toursRemis: toursRemis,
          toursTotal: tours.length,
          paiementsATemps: paiementsATemps,
          paiementsEnRetard: paiementsEnRetard,
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Membres',
          actionLabel: 'Voir tout',
          onAction: () => context.go(AppRouter.membresPath),
        ),
        AppCard(
          onTap: () => context.go(AppRouter.membresPath),
          child: Row(
            children: [
              if (membresActifs.isEmpty)
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.canvas, shape: BoxShape.circle),
                  child: const Icon(Icons.groups_rounded, color: AppColors.indigo, size: 20),
                )
              else
                _PileAvatars(membres: membresActifs),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  actifs == 0
                      ? 'Aucun membre actif pour le moment'
                      : '$actifs membre${actifs > 1 ? 's' : ''} actif${actifs > 1 ? 's' : ''}',
                  style: AppTypography.body,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate),
            ],
          ),
        ),
      ],
    );
  }

  String _sousTitre(int declarationsEnAttente) => switch (declarationsEnAttente) {
        0 => 'Voici le résumé de votre tontine.',
        1 => 'Un paiement attend votre validation.',
        final n => '$n paiements attendent votre validation.',
      };
}

/// Jusqu'à quatre avatars qui se chevauchent, puis « +N » : on voit qui
/// compose le groupe sans ouvrir la liste.
class _PileAvatars extends StatelessWidget {
  const _PileAvatars({required this.membres});

  final List<Membre> membres;

  static const _taille = 36.0;
  static const _decalage = 24.0;
  static const _maximum = 4;

  @override
  Widget build(BuildContext context) {
    final visibles = membres.take(_maximum).toList(growable: false);
    final reste = membres.length - visibles.length;
    final pastilles = [
      for (final membre in visibles) MemberAvatar(nomComplet: membre.nomComplet, size: _taille),
      if (reste > 0)
        Container(
          width: _taille,
          height: _taille,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.canvas, shape: BoxShape.circle),
          child: Text('+$reste', style: AppTypography.micro),
        ),
    ];
    return SizedBox(
      width: _taille + _decalage * (pastilles.length - 1),
      height: _taille,
      child: Stack(
        children: [
          for (var i = 0; i < pastilles.length; i++)
            Positioned(
              left: i * _decalage,
              // Liseré blanc : sépare les avatars qui se chevauchent.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: pastilles[i],
              ),
            ),
        ],
      ),
    );
  }
}
