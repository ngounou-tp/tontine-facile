import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../cotisations/application/cotisations_providers.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/espace_membre_providers.dart';
import '../widgets/mes_noms_list.dart';
import '../widgets/situation_membre_card.dart';
import '../../../../l10n/l10n.dart';

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
    final confirme = await confirmer(
      context,
      titre: context.l10n.settingsSignOutTitle,
      message: context.l10n.settingsSignOutMessage,
      libelleConfirmation: context.l10n.commonSignOut,
    );
    if (confirme) {
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
        title: Text(tontineAsync.value?.nom ?? context.l10n.memberSpaceTitle),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRouter.groupesPath),
            tooltip: context.l10n.groupsSwitch,
            icon: const Icon(Icons.swap_horiz),
          ),
          IconButton(
            onPressed: () => _confirmerDeconnexion(context, ref),
            tooltip: context.l10n.commonSignOut,
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
          message: context.l10n.memberSpaceLoadError,
          onRetry: () => ref.invalidate(tontineProvider),
        ),
        data: (tontine) => tontine == null || membre == null
            ? ErrorView(message: context.l10n.memberSpaceNoMember)
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
          Text(context.l10n.homeHelloName(membre.nomComplet.split(' ').first), style: AppTypography.screenTitle),
          const SizedBox(height: AppSpacing.lg),
          SituationMembreCard(
            nomTontine: tontine.nom,
            nombreDeNoms: mesNoms.length,
            prochainTour: prochainTour,
            prochainNom: prochainNom,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (tours.isEmpty)
            EmptyState(
              compact: true,
              icon: Icons.event_note_outlined,
              message: context.l10n.memberSpaceScheduleNotGenerated,
            )
          else if (tourActuel == null)
            EmptyState(
              compact: true,
              icon: Icons.celebration_outlined,
              message: context.l10n.memberSpaceAllTurnsPaid,
            )
          else ...[
            SectionHeader(title: context.l10n.memberSpaceToPayThisTurn),
            MesNomsList(
              situations: situations,
              onDeclarer: (situation) =>
                  context.go('${AppRouter.espaceMembrePath}/declarer/${situation.nom.id}'),
            ),
          ],
          if (mesDeclarations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: context.l10n.memberSpaceMyDeclarations),
            // Une seule carte, des lignes séparées : une liste de reçus se
            // parcourt d'un trait, comme un relevé bancaire.
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < mesDeclarations.length; i++) ...[
                    if (i > 0) const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                    _LigneReleve(
                      icone: Icons.receipt_long_outlined,
                      titre: formatAmount(mesDeclarations[i].montantDeclare),
                      sousTitre: mesDeclarations[i].motifContestation ??
                          context.l10n.memberSpaceDeclaredOn(formatDate(mesDeclarations[i].datePaiement)),
                      trailing: switch (mesDeclarations[i].statut.name) {
                        'enAttente' => AppPill(label: context.l10n.declStatusPending, tone: AppTone.warning),
                        'validee' => AppPill(label: context.l10n.declStatusApproved, tone: AppTone.success),
                        _ => AppPill(label: context.l10n.declStatusDisputed, tone: AppTone.danger),
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (mesCotisations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: context.l10n.memberSpaceContributionHistory),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < mesCotisations.length; i++) ...[
                    if (i > 0) const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                    _LigneReleve(
                      icone: Icons.check_circle_outline,
                      couleurIcone: AppColors.success,
                      titre: formatAmount(mesCotisations[i].montantVerse),
                      sousTitre: context.l10n.declPaidOn(formatDate(mesCotisations[i].datePaiement)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne d'un relevé (déclaration ou cotisation) : icône, montant, détail
/// et statut éventuel.
class _LigneReleve extends StatelessWidget {
  const _LigneReleve({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    this.couleurIcone = AppColors.indigo,
    this.trailing,
  });

  final IconData icone;
  final Color couleurIcone;
  final String titre;
  final String sousTitre;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icone, size: 22, color: couleurIcone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: AppTypography.amountInline),
                Text(sousTitre, style: AppTypography.secondary, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
        ],
      ),
    );
  }
}
