import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/changement.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/enums/statut_tour.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../membres/application/membres_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/echeancier_providers.dart';
import '../../application/reorganisation_controller.dart';
import '../widgets/motif_reorganisation_dialog.dart';
import '../widgets/tour_card.dart';
import '../widgets/tour_progress.dart';
import '../../../../l10n/l10n.dart';

/// Onglet Échéancier : programme complet des tours en lecture seule. Les
/// tours pas encore remis (« À venir ») peuvent être réordonnés par
/// glisser-déposer — un tour remis ne peut plus bouger, voir
/// `ReorganisateurTours`.
class EcheancierPage extends ConsumerWidget {
  const EcheancierPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tontineAsync = ref.watch(tontineProvider);
    final toursAsync = ref.watch(toursProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final membresAsync = ref.watch(membresProvider);
    final changements = ref.watch(changementsProvider).value ?? const [];

    final tours = toursAsync.value ?? const <Tour>[];
    final aVenir = tours.where((t) => t.statut != StatutTour.remis).length;
    final historique = tours.length - aVenir;

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        selectedNavIndex: 2,
        appBar: AppBar(
          title: Text(context.l10n.navSchedule),
          bottom: tours.isEmpty
              ? null
              : TabBar(
                  tabs: [
                    Tab(text: context.l10n.scheduleTabUpcoming(aVenir)),
                    Tab(text: context.l10n.scheduleTabHistory(historique)),
                  ],
                ),
        ),
        body: toursAsync.hasError || nomsAsync.hasError || membresAsync.hasError
            ? ErrorView(
                message: context.l10n.scheduleLoadError,
                onRetry: () {
                  ref.invalidate(toursProvider);
                  ref.invalidate(nomsProvider);
                  ref.invalidate(membresProvider);
                },
              )
            : (toursAsync.isLoading && !toursAsync.hasValue)
                ? const LoadingView()
                : _Contenu(
                    tontine: tontineAsync.value,
                    tours: tours,
                    noms: nomsAsync.value ?? const [],
                    membres: membresAsync.value ?? const [],
                    changements: changements,
                  ),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.tontine,
    required this.tours,
    required this.noms,
    required this.membres,
    required this.changements,
  });

  final Tontine? tontine;
  final List<Tour> tours;
  final List<Nom> noms;
  final List membres;
  final List<Changement> changements;

  Nom? _nom(String nomId) {
    for (final nom in noms) {
      if (nom.id == nomId) return nom;
    }
    return null;
  }

  Future<void> _deplacer(
    BuildContext context,
    WidgetRef ref,
    List<Tour> aVenir,
    int oldIndex,
    int newIndex,
  ) async {
    final tontineActuelle = tontine;
    if (tontineActuelle == null) return;
    // `onReorderItem` fournit déjà l'index d'arrivée corrigé (élément
    // retiré de sa place d'origine) : pas d'ajustement manuel.
    if (oldIndex == newIndex) return;
    final depart = aVenir[oldIndex];
    final arrivee = aVenir[newIndex];

    final motif = await demanderMotifReorganisation(context);
    if (motif == null || !context.mounted) return;
    final adminUid = ref.read(sessionProvider).value?.utilisateur.uid;
    if (adminUid == null) return;

    try {
      await ref.read(reorganisationControllerProvider.notifier).deplacer(
            tontineId: tontineActuelle.id,
            tontine: tontineActuelle,
            tours: tours,
            anciennePosition: depart.position,
            nouvellePosition: arrivee.position,
            motif: motif,
            auteurUid: adminUid,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    if (tours.isEmpty) {
      return EmptyState(
        title: context.l10n.scheduleNoCalendarYet,
        message: context.l10n.tourScheduleToPrepareMessage,
        icon: Icons.calendar_month_outlined,
        actionLabel: isAdmin ? context.l10n.tourGoToMembers : null,
        onAction: isAdmin ? () => context.go(AppRouter.membresPath) : null,
      );
    }

    final ordonnes = [...tours]..sort((a, b) => a.position.compareTo(b.position));
    final aVenir = ordonnes.where((t) => t.statut != StatutTour.remis).toList(growable: false);
    final historique = ordonnes.where((t) => t.statut == StatutTour.remis).toList(growable: false);
    final busy = ref.watch(reorganisationControllerProvider).isLoading;

    return SafeArea(
      child: TabBarView(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: TourProgress(tours: ordonnes),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (isAdmin && aVenir.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_indicator, size: 16, color: AppColors.slate),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          context.l10n.scheduleDragHint,
                          style: AppTypography.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AbsorbPointer(
                  absorbing: busy,
                  child: isAdmin
                      ? ReorderableListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          onReorderItem: (oldIndex, newIndex) =>
                              _deplacer(context, ref, aVenir, oldIndex, newIndex),
                          children: [
                            for (final tour in aVenir)
                              Padding(
                                key: ValueKey(tour.id),
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: TourCard(
                                  tour: tour,
                                  nom: _nom(tour.nomId),
                                  membres: membres.cast(),
                                  changements: changements,
                                  enEvidence: tour.statut == StatutTour.enCours,
                                  onTap: tour.statut == StatutTour.enCours
                                      ? () => context.go('${AppRouter.cotisationsPath}/${tour.id}')
                                      : null,
                                ),
                              ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          children: [
                            for (final tour in aVenir)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: TourCard(
                                  tour: tour,
                                  nom: _nom(tour.nomId),
                                  membres: membres.cast(),
                                  changements: changements,
                                  enEvidence: tour.statut == StatutTour.enCours,
                                  onTap: tour.statut == StatutTour.enCours
                                      ? () => context.go('${AppRouter.cotisationsPath}/${tour.id}')
                                      : null,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          historique.isEmpty
              ? EmptyState(
                  icon: Icons.history,
                  message: context.l10n.scheduleNoTurnPaid,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    for (final tour in historique)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TourCard(
                          tour: tour,
                          nom: _nom(tour.nomId),
                          membres: membres.cast(),
                          changements: changements,
                          onTap: () => context.go('${AppRouter.cotisationsPath}/${tour.id}'),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}
