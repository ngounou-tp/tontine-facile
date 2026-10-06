import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../domain/enums/statut_cotisation.dart';
import '../../../../domain/services/calculateur_cotisation.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/member_avatar.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../../membres/presentation/widgets/parts_editor.dart'
    show formatFraction;
import '../../../tontine/application/tontine_providers.dart';
import '../../application/cotisation_controller.dart';
import '../../application/cotisations_providers.dart';
import '../widgets/cotisation_form.dart';
import '../../../../l10n/l10n.dart';

const _calculateur = CalculateurCotisation();

/// Écran de collecte d'un tour : liste chaque détentrice/détenteur de part
/// avec son montant dû et déjà versé, et permet à l'administratrice de
/// saisir sa cotisation via [CotisationForm] dans une feuille modale. Un
/// membre y accède en lecture seule (voir `isAdminProvider`) : il peut voir
/// qui a déjà contribué pour ce tour, sans pouvoir saisir de cotisation.
class SaisirCotisationPage extends ConsumerWidget {
  const SaisirCotisationPage({required this.tourId, super.key});

  final String tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final tontineAsync = ref.watch(tontineProvider);
    final toursAsync = ref.watch(toursProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final membresAsync = ref.watch(membresProvider);
    final cotisationsAsync = ref.watch(cotisationsProvider);

    final asyncValues = [
      sessionAsync,
      tontineAsync,
      toursAsync,
      nomsAsync,
      membresAsync,
      cotisationsAsync,
    ];
    final chargement = asyncValues.any((a) => a.isLoading && !a.hasValue);
    final enErreur = asyncValues.any((a) => a.hasError);

    if (enErreur) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRouter.echeancierPath),
          ),
        ),
        body: ErrorView(
          message: context.l10n.collectLoadError,
          onRetry: () {
            ref.invalidate(sessionProvider);
            ref.invalidate(tontineProvider);
            ref.invalidate(toursProvider);
            ref.invalidate(nomsProvider);
            ref.invalidate(membresProvider);
            ref.invalidate(cotisationsProvider);
          },
        ),
      );
    }
    if (chargement) return const Scaffold(body: LoadingView());

    final adminUid = sessionAsync.value?.utilisateur.uid;
    final tontine = tontineAsync.value;
    final tour = (toursAsync.value ?? const <Tour>[])
        .where((t) => t.id == tourId)
        .cast<Tour?>()
        .firstOrNull;
    if (adminUid == null || tontine == null || tour == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRouter.echeancierPath),
          ),
        ),
        body: ErrorView(message: context.l10n.collectTurnNotFound),
      );
    }

    final noms = nomsAsync.value ?? const <Nom>[];
    final membres = membresAsync.value ?? const <Membre>[];
    final cotisations = cotisationsAsync.value ?? const [];

    return _Contenu(
      adminUid: adminUid,
      tontine: tontine,
      tour: tour,
      noms: noms,
      membres: membres,
      cotisations: cotisations,
    );
  }
}

class _Detenteur {
  const _Detenteur({
    required this.nom,
    required this.membre,
    required this.fraction,
    required this.montantDu,
    required this.montantVerse,
  });

  final Nom nom;
  final Membre membre;
  final double fraction;
  final int montantDu;
  final int montantVerse;

  int get resteADu => montantDu - montantVerse;
  bool get solde => montantVerse >= montantDu;
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.adminUid,
    required this.tontine,
    required this.tour,
    required this.noms,
    required this.membres,
    required this.cotisations,
  });

  final String adminUid;
  final Tontine tontine;
  final Tour tour;
  final List<Nom> noms;
  final List<Membre> membres;
  final List cotisations;

  Membre? _membre(String membreId) {
    for (final membre in membres) {
      if (membre.id == membreId) return membre;
    }
    return null;
  }

  List<_Detenteur> _detenteurs() {
    final resultat = <_Detenteur>[];
    for (final nom in noms) {
      for (final part in nom.parts) {
        final membre = _membre(part.membreId);
        if (membre == null) continue;
        final montantDu = _calculateur.calculerMontantDuPourMembre(
          tontine: tontine,
          nom: nom,
          membreId: membre.id,
        );
        final montantVerse = cotisations
            .where((c) =>
                c.tourId == tour.id &&
                c.nomId == nom.id &&
                c.membreId == membre.id &&
                c.statut == StatutCotisation.validee)
            .fold<int>(0, (somme, c) => somme + (c.montantVerse as int));
        resultat.add(_Detenteur(
          nom: nom,
          membre: membre,
          fraction: part.fraction,
          montantDu: montantDu,
          montantVerse: montantVerse,
        ));
      }
    }
    return resultat;
  }

  Future<void> _ouvrirFormulaire(
    BuildContext context,
    WidgetRef ref,
    _Detenteur detenteur,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(detenteur.membre.nomComplet, style: AppTypography.screenTitle),
              const SizedBox(height: 2),
              Text(
                '${detenteur.nom.libelle} · ${formatFraction(detenteur.fraction)}',
                style: AppTypography.secondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Consumer(
                builder: (context, ref, _) {
                  final busy = ref.watch(cotisationControllerProvider).isLoading;
                  return CotisationForm(
                    montantDu: detenteur.resteADu,
                    calculerPenalite: (datePaiement) => _calculateur.calculerPenalite(
                      tontine: tontine,
                      nom: detenteur.nom,
                      datePaiement: datePaiement,
                      dateEcheance: tour.datePrevue,
                    ),
                    busy: busy,
                    onSubmit: (valeur) => _enregistrer(context, ref, detenteur, valeur),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enregistrer(
    BuildContext context,
    WidgetRef ref,
    _Detenteur detenteur,
    CotisationFormValue valeur,
  ) async {
    try {
      await ref.read(cotisationControllerProvider.notifier).saisirCotisation(
            tontineId: tontine.id,
            tontine: tontine,
            tour: tour,
            nom: detenteur.nom,
            membreId: detenteur.membre.id,
            adminUid: adminUid,
            montantVerse: valeur.montantVerse,
            datePaiement: valeur.datePaiement,
            preuveBytes: valeur.preuve,
            motifException: valeur.motifException,
            exonererPenalite: valeur.exonererPenalite,
          );
      if (context.mounted) {
        // Vibration courte : confirme physiquement l'encaissement, le geste
        // le plus important de l'app.
        HapticFeedback.mediumImpact();
        ref.read(flashMessageProvider.notifier).set(
              context.l10n.collectRecorded(detenteur.membre.nomComplet),
            );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlashMessageListener.attach(ref, context);
    final isAdmin = ref.watch(isAdminProvider);
    final detenteurs = _detenteurs();
    final nonSoldes = detenteurs.where((d) => !d.solde).toList(growable: false);
    final soldes = detenteurs.where((d) => d.solde).toList(growable: false);
    final totalAttendu = detenteurs.fold<int>(0, (s, d) => s + d.montantDu);
    final totalCollecte = detenteurs.fold<int>(0, (s, d) => s + d.montantVerse);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: context.l10n.commonBack,
            onPressed: () => context.go(AppRouter.echeancierPath),
          ),
          title: Text(
            isAdmin
                ? context.l10n.collectTitleAdmin(tour.position)
                : context.l10n.collectTitleMember(tour.position),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.collectTabToCollect(nonSoldes.length)),
              Tab(text: context.l10n.collectTabSettled(soldes.length)),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _ResumeCollecte(
                  tour: tour,
                  totalCollecte: totalCollecte,
                  totalAttendu: totalAttendu,
                  restants: nonSoldes.length,
                ),
              ),
              Expanded(
                child: detenteurs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            context.l10n.collectNoHolders,
                            style: AppTypography.secondary,
                          ),
                        ),
                      )
                    : TabBarView(
                        children: [
                          _ListeDetenteurs(
                            detenteurs: nonSoldes,
                            tour: tour,
                            messageVide: context.l10n.collectEveryonePaid,
                            onTapDetenteur: !isAdmin
                                ? null
                                : (detenteur) => _ouvrirFormulaire(context, ref, detenteur),
                          ),
                          _ListeDetenteurs(
                            detenteurs: soldes,
                            tour: tour,
                            messageVide: context.l10n.collectNoPaymentsYet,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête de la collecte : combien est rentré, sur combien, et combien de
/// personnes restent à relancer. La jauge avance sous les yeux de
/// l'administratrice à chaque cotisation enregistrée.
class _ResumeCollecte extends StatelessWidget {
  const _ResumeCollecte({
    required this.tour,
    required this.totalCollecte,
    required this.totalAttendu,
    required this.restants,
  });

  final Tour tour;
  final int totalCollecte;
  final int totalAttendu;
  final int restants;

  @override
  Widget build(BuildContext context) {
    final complet = totalAttendu > 0 && totalCollecte >= totalAttendu;
    final progression = totalAttendu <= 0 ? 0.0 : totalCollecte / totalAttendu;
    return Card(
      color: AppColors.ink,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.collectDueOverline(formatDateCourte(tour.datePrevue).toUpperCase()),
              style: AppTypography.overline.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatAmount(totalCollecte),
              style: AppTypography.amountXl.copyWith(color: AppColors.surface),
            ),
            Text(
              context.l10n.tourCollectedOf(formatAmount(totalAttendu)),
              style: AppTypography.secondary.copyWith(color: AppColors.onInkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppProgressBar(
              value: progression,
              color: complet ? AppColors.success : AppColors.accent,
              trackColor: AppColors.surface.withValues(alpha: 0.14),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: AppMotion.medium,
              child: Row(
                key: ValueKey(complet),
                children: [
                  Icon(
                    complet ? Icons.check_circle : Icons.schedule,
                    size: 16,
                    color: complet ? AppColors.success : AppColors.onInkMuted,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Flexible(
                    child: Text(
                      complet
                          ? context.l10n.collectComplete
                          : context.l10n.collectPeopleLeft(restants),
                      style: AppTypography.secondary.copyWith(
                        color: complet ? AppColors.surface : AppColors.onInkMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeDetenteurs extends StatelessWidget {
  const _ListeDetenteurs({
    required this.detenteurs,
    required this.tour,
    required this.messageVide,
    this.onTapDetenteur,
  });

  final List<_Detenteur> detenteurs;
  final Tour tour;
  final String messageVide;
  final void Function(_Detenteur detenteur)? onTapDetenteur;

  @override
  Widget build(BuildContext context) {
    if (detenteurs.isEmpty) {
      return EmptyState(icon: Icons.task_alt, message: messageVide);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
      children: [
        for (final detenteur in detenteurs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _DetenteurCard(
              detenteur: detenteur,
              tour: tour,
              onTap: onTapDetenteur == null ? null : () => onTapDetenteur!(detenteur),
            ),
          ),
      ],
    );
  }
}

class _DetenteurCard extends StatelessWidget {
  const _DetenteurCard({required this.detenteur, required this.tour, required this.onTap});

  final _Detenteur detenteur;
  final Tour tour;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enRetard = !detenteur.solde && DateTime.now().isAfter(tour.datePrevue);
    final (statut, ton) = switch (true) {
      _ when detenteur.solde => (context.l10n.statusPaid, AppTone.success),
      _ when enRetard => (context.l10n.statusLate, AppTone.danger),
      _ when detenteur.montantVerse > 0 => (context.l10n.statusPartial, AppTone.warning),
      _ => (context.l10n.statusUnpaid, AppTone.neutral),
    };
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          MemberAvatar(nomComplet: detenteur.membre.nomComplet),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detenteur.membre.nomComplet,
                  style: AppTypography.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    '${detenteur.nom.libelle} · ${formatFraction(detenteur.fraction)}',
                    if (!detenteur.solde && detenteur.montantVerse > 0)
                      context.l10n.collectRemainingOf(formatAmount(detenteur.montantDu)),
                  ].join(' · '),
                  style: AppTypography.secondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Montant et statut à droite, alignés en colonne d'une ligne à
          // l'autre (chiffres tabulaires) : ce qui reste à encaisser se lit
          // en premier.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatAmount(detenteur.solde ? detenteur.montantDu : detenteur.resteADu),
                style: AppTypography.amountInline,
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppPill(label: statut, tone: ton),
            ],
          ),
        ],
      ),
    );
  }
}
