import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../cotisations/application/cotisations_providers.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/espace_membre_providers.dart';
import '../widgets/mes_noms_list.dart';
import '../widgets/situation_membre_card.dart';

/// Espace du membre (non-administratrice) : sa situation vis-à-vis de la
/// tontine, ses noms et leur statut pour le tour en cours, historique de
/// ses cotisations, et l'action « J'ai payé » quand elle est possible.
///
/// N'utilise pas [AppScaffold] (mise en page différente, sans onglet actif),
/// mais affiche la même barre de navigation : un membre peut aussi consulter
/// Accueil, Membres, Échéancier, Réglages et Déclarations en lecture seule
/// (voir `isAdminProvider` et `AppRouter.redirect`).
class EspaceMembrePage extends ConsumerWidget {
  const EspaceMembrePage({super.key});

  Future<void> _confirmerDeconnexion(BuildContext context, WidgetRef ref) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez vous reconnecter pour accéder à votre tontine.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await ref.read(authControllerProvider.notifier).deconnecter();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlashMessageListener.attach(ref, context);
    final tontineAsync = ref.watch(tontineProvider);
    final membre = ref.watch(membreCourantProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tontineAsync.value?.nom ?? 'Mon espace'),
        actions: [
          IconButton(
            onPressed: () => _confirmerDeconnexion(context, ref),
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      bottomNavigationBar: AppNavigation(
        selectedIndex: 0,
        onSelected: (index) => AppNavigation.go(context, index),
      ),
      body: tontineAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'Impossible de charger votre espace.',
          onRetry: () => ref.invalidate(tontineProvider),
        ),
        data: (tontine) => tontine == null || membre == null
            ? const ErrorView(message: 'Aucune fiche membre associée à ce compte.')
            : _Contenu(tontine: tontine, membre: membre),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.tontine, required this.membre});

  final Tontine tontine;
  final Membre membre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesNoms = ref.watch(mesNomsProvider);
    final tourActuel = ref.watch(tourActuelProvider);
    final prochainTour = ref.watch(prochainTourMembreProvider);
    final situations = ref.watch(mesSituationsTourActuelProvider);
    final mesCotisations = ref.watch(mesCotisationsProvider);
    final mesDeclarations = ref.watch(mesDeclarationsProvider);
    final tours = ref.watch(toursProvider).value ?? const [];

    Nom? prochainNom;
    for (final detenu in mesNoms) {
      if (prochainTour != null && detenu.nom.id == prochainTour.nomId) {
        prochainNom = detenu.nom;
      }
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        children: [
          Text('Bonjour, ${membre.nomComplet.split(' ').first}', style: AppTypography.screenTitle),
          const SizedBox(height: AppSpacing.lg),
          SituationMembreCard(
            nomTontine: tontine.nom,
            nombreDeNoms: mesNoms.length,
            prochainTour: prochainTour,
            prochainNom: prochainNom,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (tours.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  "L'échéancier n'a pas encore été généré par l'administratrice.",
                  style: AppTypography.secondary,
                ),
              ),
            )
          else if (tourActuel == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('Tous les tours ont été remis.', style: AppTypography.body),
              ),
            )
          else ...[
            Text('Mes noms — tour en cours', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            MesNomsList(
              situations: situations,
              onDeclarer: (situation) =>
                  context.go('${AppRouter.espaceMembrePath}/declarer/${situation.nom.id}'),
            ),
          ],
          if (mesDeclarations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Mes déclarations', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            for (final declaration in mesDeclarations)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${declaration.montantDeclare} FCFA',
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (declaration.motifContestation != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                declaration.motifContestation!,
                                style: AppTypography.secondary,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        switch (declaration.statut.name) {
                          'enAttente' => 'En attente',
                          'validee' => 'Validée',
                          _ => 'Contestée',
                        },
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (mesCotisations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Historique des cotisations', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            for (final cotisation in mesCotisations)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cotisation.montantVerse} FCFA',
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${cotisation.datePaiement.day.toString().padLeft(2, '0')}/'
                        '${cotisation.datePaiement.month.toString().padLeft(2, '0')}/'
                        '${cotisation.datePaiement.year}',
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
