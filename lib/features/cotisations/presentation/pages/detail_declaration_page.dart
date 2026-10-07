import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/declaration.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/member_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/cotisations_providers.dart';
import '../../application/declaration_controller.dart';
import '../../../../l10n/l10n.dart';

/// Détail d'une déclaration de paiement, avec preuve. Les actions de
/// traitement (validation ou refus) ne sont visibles que pour
/// l'administratrice, sur une déclaration encore en attente — les membres
/// consultent cet écran en lecture seule.
class DetailDeclarationPage extends ConsumerWidget {
  const DetailDeclarationPage({required this.declarationId, super.key});

  final String declarationId;

  Future<void> _valider(
    BuildContext context,
    WidgetRef ref,
    String tontineId,
    Declaration declaration,
    Tontine tontine,
    Nom nom,
    Tour tour,
  ) async {
    final adminUid = ref.read(sessionProvider).value?.utilisateur.uid;
    if (adminUid == null) return;
    try {
      await ref.read(declarationControllerProvider.notifier).validerDeclaration(
            tontineId: tontineId,
            declaration: declaration,
            tontine: tontine,
            nom: nom,
            tour: tour,
            adminUid: adminUid,
          );
      if (context.mounted) {
        ref.read(flashMessageProvider.notifier).set(L10n.current.declValidated);
        context.go(AppRouter.declarationsPath);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  Future<void> _refuser(
    BuildContext context,
    WidgetRef ref,
    String tontineId,
    Declaration declaration,
  ) async {
    final motif = await showDialog<String>(
      context: context,
      builder: (context) => const _MotifRefusDialog(),
    );
    if (motif == null || !context.mounted) return;
    try {
      await ref.read(declarationControllerProvider.notifier).refuserDeclaration(
            tontineId: tontineId,
            declaration: declaration,
            motif: motif,
          );
      if (context.mounted) {
        ref.read(flashMessageProvider.notifier).set(L10n.current.declRejected);
        context.go(AppRouter.declarationsPath);
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
    final tontineId = ref.watch(currentTontineIdProvider);
    final tontineAsync = ref.watch(tontineProvider);
    final declarationsAsync = ref.watch(declarationsProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final membresAsync = ref.watch(membresProvider);
    final toursAsync = ref.watch(toursProvider);

    final chargement = [tontineAsync, declarationsAsync, nomsAsync, membresAsync, toursAsync]
        .any((a) => a.isLoading && !a.hasValue);
    final enErreur =
        [tontineAsync, declarationsAsync, nomsAsync, membresAsync, toursAsync].any((a) => a.hasError);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.commonBack,
          onPressed: () => context.go(AppRouter.declarationsPath),
        ),
        title: Text(context.l10n.declTitle),
      ),
      body: enErreur
          ? ErrorView(
              message: context.l10n.declLoadError,
              onRetry: () {
                ref.invalidate(tontineProvider);
                ref.invalidate(declarationsProvider);
                ref.invalidate(nomsProvider);
                ref.invalidate(membresProvider);
                ref.invalidate(toursProvider);
              },
            )
          : chargement
              ? const LoadingView()
              : _Contenu(
                  declarationId: declarationId,
                  tontineId: tontineId,
                  tontine: tontineAsync.value,
                  declarations: declarationsAsync.value ?? const [],
                  noms: nomsAsync.value ?? const [],
                  membres: membresAsync.value ?? const [],
                  tours: toursAsync.value ?? const [],
                  isAdmin: ref.watch(isAdminProvider),
                  monMembreId: ref.watch(sessionProvider).value?.profil?.membreId,
                  onValider: (declaration, tontine, nom, tour) =>
                      _valider(context, ref, tontineId!, declaration, tontine, nom, tour),
                  onRefuser: (declaration) => _refuser(context, ref, tontineId!, declaration),
                ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.declarationId,
    required this.tontineId,
    required this.tontine,
    required this.declarations,
    required this.noms,
    required this.membres,
    required this.tours,
    required this.isAdmin,
    required this.monMembreId,
    required this.onValider,
    required this.onRefuser,
  });

  final String declarationId;
  final String? tontineId;
  final Tontine? tontine;
  final List<Declaration> declarations;
  final List<Nom> noms;
  final List<Membre> membres;
  final List<Tour> tours;
  final bool isAdmin;
  final String? monMembreId;
  final void Function(Declaration declaration, Tontine tontine, Nom nom, Tour tour) onValider;
  final void Function(Declaration declaration) onRefuser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Declaration? declaration;
    for (final candidat in declarations) {
      if (candidat.id == declarationId) {
        declaration = candidat;
        break;
      }
    }
    if (declaration == null || tontine == null || tontineId == null) {
      return ErrorView(message: context.l10n.declNotFound);
    }

    Nom? nom;
    for (final candidat in noms) {
      if (candidat.id == declaration.nomId) nom = candidat;
    }
    Membre? membre;
    for (final candidat in membres) {
      if (candidat.id == declaration.membreId) membre = candidat;
    }
    Tour? tour;
    for (final candidat in tours) {
      if (candidat.id == declaration.tourId) tour = candidat;
    }

    final busy = ref.watch(declarationControllerProvider).isLoading;
    final peutTraiter =
        isAdmin && declaration.statut.name == 'enAttente' && nom != null && tour != null;
    // Une déclaration refusée ou validée partiellement (montant inférieur
    // au montant dû) n'empêche pas l'auteur d'en refaire une : les règles
    // Firestore n'autorisent de toute façon qu'à *créer* une nouvelle
    // déclaration, jamais à modifier celle-ci. L'écran de dépôt
    // (`DeclarerPaiementPage`) reste seul juge de l'éligibilité réelle
    // (tour toujours en cours, reste à devoir) : ce bouton n'est qu'un
    // raccourci.
    final peutRedeclarer = !isAdmin &&
        monMembreId != null &&
        monMembreId == declaration.membreId &&
        declaration.statut.name != 'enAttente';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  MemberAvatar(nomComplet: membre?.nomComplet ?? '?', size: 48),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membre?.nomComplet ?? context.l10n.unknownMember,
                          style: AppTypography.sectionTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            nom?.libelle ?? context.l10n.unknownName,
                            if (tour != null) context.l10n.turnLabel(tour.position),
                          ].join(' · '),
                          style: AppTypography.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Le montant est la seule information à vérifier contre la
              // preuve : il passe en tête, en grand.
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(context.l10n.declAmountDeclared, style: AppTypography.secondary)),
                        _pastilleStatut(context, declaration.statut.name),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(formatAmount(declaration.montantDeclare), style: AppTypography.amountXl),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.l10n.declPaidOn(formatDate(declaration.datePaiement)),
                      style: AppTypography.secondary,
                    ),
                    if (declaration.motifContestation != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppPill.backgroundOf(AppTone.danger),
                          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                        ),
                        child: Text(
                          context.l10n.declRejectionReason(declaration.motifContestation!),
                          style: AppTypography.secondary.copyWith(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: context.l10n.declProofOfPayment),
              _CartePreuve(preuveId: declaration.preuveId),
              if (peutTraiter) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: context.l10n.declApprove,
                  variant: AppButtonVariant.accent,
                  busy: busy,
                  onPressed: busy ? null : () => onValider(declaration!, tontine!, nom!, tour!),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: context.l10n.declReject,
                  variant: AppButtonVariant.destructive,
                  busy: busy,
                  onPressed: busy ? null : () => onRefuser(declaration!),
                ),
              ],
              if (peutRedeclarer) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: context.l10n.declNewDeclaration,
                  variant: AppButtonVariant.accent,
                  onPressed: () => context.go(
                    '${AppRouter.espaceMembrePath}/declarer/${declaration!.nomId}',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pastilleStatut(BuildContext context, String statut) => switch (statut) {
        'enAttente' => AppPill(label: context.l10n.declStatusPending, tone: AppTone.warning),
        'validee' => AppPill(label: context.l10n.declStatusApproved, tone: AppTone.success),
        _ => AppPill(label: context.l10n.declStatusDisputed, tone: AppTone.danger),
      };
}

class _CartePreuve extends ConsumerWidget {
  const _CartePreuve({required this.preuveId});

  final String preuveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preuveAsync = ref.watch(preuveProvider(preuveId));
    // Même hauteur réservée en chargement et une fois l'image affichée : la
    // page ne saute pas quand la preuve arrive.
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.easeOut,
      child: preuveAsync.when(
        loading: () => Container(
          key: const ValueKey('chargement'),
          height: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
        error: (_, _) => EmptyState(
          key: const ValueKey('erreur'),
          compact: true,
          icon: Icons.broken_image_outlined,
          message: context.l10n.declProofLoadError,
        ),
        data: (preuve) {
          if (preuve == null) {
            return EmptyState(
              key: const ValueKey('vide'),
              compact: true,
              icon: Icons.image_not_supported_outlined,
              message: context.l10n.declNoProof,
            );
          }
          final octets = base64Decode(preuve.imageEncodee);
          return Semantics(
            key: const ValueKey('image'),
            button: true,
            label: context.l10n.declEnlargeProof,
            child: GestureDetector(
              onTap: () => _agrandir(context, octets),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: Image.memory(octets, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      child: const Icon(Icons.zoom_out_map, size: 18, color: AppColors.surface),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Plein écran zoomable : une capture de reçu Mobile Money se lit mal en
  /// vignette (montant, référence de transaction).
  void _agrandir(BuildContext context, Uint8List octets) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(context.l10n.declProofOfPayment),
          ),
          body: InteractiveViewer(
            maxScale: 5,
            child: Center(child: Image.memory(octets)),
          ),
        ),
      ),
    );
  }
}

class _MotifRefusDialog extends StatefulWidget {
  const _MotifRefusDialog();

  @override
  State<_MotifRefusDialog> createState() => _MotifRefusDialogState();
}

class _MotifRefusDialogState extends State<_MotifRefusDialog> {
  final _motif = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _confirmer() {
    final valeur = _motif.text.trim();
    if (valeur.isEmpty) {
      setState(() => _erreur = context.l10n.declRejectReasonRequired);
      return;
    }
    Navigator.of(context).pop(valeur);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.declRejectTitle),
      content: TextField(
        controller: _motif,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: context.l10n.declRejectHint,
          errorText: _erreur,
        ),
        onChanged: (_) {
          if (_erreur != null) setState(() => _erreur = null);
        },
      ),
      actions: [
        AppButton(
          label: context.l10n.commonCancel,
          variant: AppButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: context.l10n.commonConfirm,
          variant: AppButtonVariant.destructive,
          onPressed: _confirmer,
        ),
      ],
    );
  }
}
