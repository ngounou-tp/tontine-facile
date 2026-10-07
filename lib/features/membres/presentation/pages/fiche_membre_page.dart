import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/services/calculateur_cotisation.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/member_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_controller.dart';
import '../../application/membres_providers.dart';
import '../widgets/membre_form.dart';
import '../widgets/nombre_de_noms_field.dart';
import '../widgets/parts_editor.dart';
import '../../../../l10n/l10n.dart';

/// Fiche d'un membre : coordonnées, code d'invitation, noms détenus et
/// montant dû par échéance, avec actions de modification, d'attribution de
/// noms supplémentaires et d'activation/désactivation.
class FicheMembrePage extends ConsumerStatefulWidget {
  const FicheMembrePage({required this.membreId, super.key});

  final String membreId;

  @override
  ConsumerState<FicheMembrePage> createState() => _FicheMembrePageState();
}

class _FicheMembrePageState extends ConsumerState<FicheMembrePage> {
  var _modification = false;

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _modifier(String tontineId, Membre membre, MembreFormValue valeur) async {
    try {
      await ref.read(membresControllerProvider.notifier).modifierMembre(
            tontineId: tontineId,
            membre: membre,
            nomComplet: valeur.nomComplet,
            email: valeur.email,
            whatsapp: valeur.whatsapp,
          );
      if (mounted) {
        setState(() => _modification = false);
        _message(context.l10n.profileContactUpdated);
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  Future<void> _basculerActif(String tontineId, Membre membre) async {
    // Désactiver retire le membre des collectes : on confirme d'abord. La
    // réactivation, sans conséquence fâcheuse, reste immédiate.
    if (membre.actif) {
      final confirme = await confirmer(
        context,
        titre: context.l10n.profileDeactivateTitle(membre.nomComplet),
        message: context.l10n.profileDeactivateMessage,
        libelleConfirmation: context.l10n.profileDeactivate,
        destructif: true,
      );
      if (!confirme || !mounted) return;
    }
    try {
      final notifier = ref.read(membresControllerProvider.notifier);
      if (membre.actif) {
        await notifier.desactiverMembre(tontineId: tontineId, membre: membre);
        if (mounted) _message(context.l10n.profileDeactivated(membre.nomComplet));
      } else {
        await notifier.reactiverMembre(tontineId: tontineId, membre: membre);
        if (mounted) _message(context.l10n.profileReactivated(membre.nomComplet));
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  Future<void> _copierCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) _message(context.l10n.addMemberCodeCopied);
  }

  Future<void> _attribuerNoms(String tontineId, Membre membre) async {
    final choix = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FeuilleAttribuerNoms(nomComplet: membre.nomComplet),
    );
    if (choix == null || choix <= 0 || !mounted) return;
    try {
      await ref.read(membresControllerProvider.notifier).attribuerNomsSupplementaires(
            tontineId: tontineId,
            membreId: membre.id,
            nombreDeNoms: choix,
          );
      if (mounted) {
        _message(context.l10n.profileNamesAssigned(formatterNombreDeNoms(choix), membre.nomComplet));
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membresAsync = ref.watch(membresProvider);
    final tontineId = ref.watch(currentTontineIdProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final monMembreId = ref.watch(sessionProvider).value?.profil?.membreId;

    if (membresAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: context.l10n.commonBack,
            onPressed: () => context.go(AppRouter.membresPath),
          ),
        ),
        body: ErrorView(
          message: context.l10n.profileLoadError,
          onRetry: () => ref.invalidate(membresProvider),
        ),
      );
    }
    if (membresAsync.isLoading && !membresAsync.hasValue || tontineId == null) {
      return const Scaffold(body: LoadingView());
    }

    final membres = membresAsync.value ?? const <Membre>[];
    Membre? membre;
    for (final candidat in membres) {
      if (candidat.id == widget.membreId) {
        membre = candidat;
        break;
      }
    }
    if (membre == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: context.l10n.commonBack,
            onPressed: () => context.go(AppRouter.membresPath),
          ),
        ),
        body: ErrorView(message: context.l10n.profileNotFound),
      );
    }
    final tontine = ref.watch(tontineProvider).value;
    final noms = ref.watch(nomsProvider).value ?? const <Nom>[];
    final busy = ref.watch(membresControllerProvider).isLoading;
    final membreActuel = membre;

    final nomsDetenus = [
      for (final nom in noms)
        for (final part in nom.parts)
          if (part.membreId == membreActuel.id) (nom: nom, fraction: part.fraction),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.commonBack,
          onPressed: _modification
              ? () => setState(() => _modification = false)
              : () => context.go(AppRouter.membresPath),
        ),
        title: Text(_modification ? context.l10n.profileEditContact : membreActuel.nomComplet),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _modification
                ? MembreForm(
                    nomComplet: membreActuel.nomComplet,
                    email: membreActuel.email ?? '',
                    whatsapp: membreActuel.whatsapp ?? '',
                    submitLabel: context.l10n.commonSave,
                    busy: busy,
                    onSubmit: (valeur) => _modifier(tontineId, membreActuel, valeur),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EnTeteMembre(membre: membreActuel),
                      const SizedBox(height: AppSpacing.lg),
                      if (membreActuel.whatsapp != null || membreActuel.email != null)
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (membreActuel.whatsapp != null)
                                _ligneContact(Icons.chat_outlined, context.l10n.contactWhatsApp, membreActuel.whatsapp!),
                              if (membreActuel.whatsapp != null && membreActuel.email != null)
                                const Divider(height: AppSpacing.lg),
                              if (membreActuel.email != null)
                                _ligneContact(Icons.mail_outline, context.l10n.authEmailLabel, membreActuel.email!),
                            ],
                          ),
                        ),
                      if (membreActuel.codeInvitation != null &&
                          (isAdmin || membreActuel.id == monMembreId)) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _carteCodeInvitation(membreActuel),
                      ],
                      if (tontine != null && nomsDetenus.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _carteMontantDu(tontine, membreActuel, nomsDetenus),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      SectionHeader(
                        title: context.l10n.profileNamesHeld,
                        actionLabel: isAdmin && (tontine == null || noms.length < tontine.nombreDeNoms)
                            ? context.l10n.membersAssign
                            : null,
                        actionIcon: Icons.add,
                        onAction: () => _attribuerNoms(tontineId, membreActuel),
                      ),
                      if (nomsDetenus.isEmpty)
                        EmptyState(
                          compact: true,
                          icon: Icons.badge_outlined,
                          message: context.l10n.profileNoNamesYet,
                        )
                      else
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final detenu in nomsDetenus)
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.canvas,
                                    child: Text(
                                      formatFraction(detenu.fraction),
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.indigo,
                                      ),
                                    ),
                                  ),
                                  title: Text(detenu.nom.libelle),
                                  trailing: isAdmin
                                      ? const Icon(Icons.chevron_right, color: AppColors.slate)
                                      : null,
                                  onTap: !isAdmin
                                      ? null
                                      : () => context.go(
                                          '${AppRouter.membresPath}/noms/${detenu.nom.id}',
                                        ),
                                ),
                            ],
                          ),
                        ),
                      if (isAdmin) ...[
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: context.l10n.profileEditContact,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => setState(() => _modification = true),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: membreActuel.actif
                              ? context.l10n.profileDeactivateMember
                              : context.l10n.profileReactivateMember,
                          variant: AppButtonVariant.destructive,
                          busy: busy,
                          onPressed: busy ? null : () => _basculerActif(tontineId, membreActuel),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _ligneContact(IconData icon, String type, String valeur) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.indigo),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: AppTypography.micro),
              Text(valeur, style: AppTypography.body, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _carteCodeInvitation(Membre membre) {
    final inscrit = membre.uid != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inscrit ? context.l10n.profileInviteCodeUsed : context.l10n.profileInviteCode,
                  style: AppTypography.secondary,
                ),
              ),
              if (inscrit) AppPill(label: context.l10n.profileRegistered, tone: AppTone.success),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  membre.codeInvitation!,
                  style: AppTypography.screenTitle.copyWith(
                    letterSpacing: 4,
                    color: inscrit ? AppColors.slate : AppColors.ink,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: context.l10n.addMemberCopyCode,
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: () => _copierCode(membre.codeInvitation!),
              ),
            ],
          ),
          if (!inscrit) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.profileShareCodeWith(membre.nomComplet),
              style: AppTypography.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _carteMontantDu(
    Tontine tontine,
    Membre membre,
    List<({Nom nom, double fraction})> nomsDetenus,
  ) {
    const calculateur = CalculateurCotisation();
    final total = nomsDetenus.fold<int>(
      0,
      (somme, detenu) => somme +
          calculateur.calculerMontantDuPourMembre(
            tontine: tontine,
            nom: detenu.nom,
            membreId: membre.id,
          ),
    );
    return AppCard(
      color: AppColors.ink,
      borderColor: AppColors.ink,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.profileDuePerDueDate, style: AppTypography.overline.copyWith(color: AppColors.accent)),
          const SizedBox(height: AppSpacing.xxs),
          Text(formatAmount(total), style: AppTypography.amountXl.copyWith(color: AppColors.surface)),
          Text(
            context.l10n.profileNamesHeldCount(nomsDetenus.length),
            style: AppTypography.secondary.copyWith(color: AppColors.onInkMuted),
          ),
        ],
      ),
    );
  }
}

class _EnTeteMembre extends StatelessWidget {
  const _EnTeteMembre({required this.membre});

  final Membre membre;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MemberAvatar(nomComplet: membre.nomComplet, size: 64),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(membre.nomComplet, style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.xxs),
              if (!membre.actif)
                AppPill(label: context.l10n.statusDeactivated, tone: AppTone.neutral)
              else if (membre.uid == null)
                AppPill(label: context.l10n.statusAwaitingSignup, tone: AppTone.warning)
              else
                AppPill(label: context.l10n.statusActive, tone: AppTone.success),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeuilleAttribuerNoms extends StatefulWidget {
  const _FeuilleAttribuerNoms({required this.nomComplet});

  final String nomComplet;

  @override
  State<_FeuilleAttribuerNoms> createState() => _FeuilleAttribuerNomsState();
}

class _FeuilleAttribuerNomsState extends State<_FeuilleAttribuerNoms> {
  var _valeur = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
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
          Text(context.l10n.profileAssignNamesTitle, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.profileAssignNamesQuestion(widget.nomComplet),
            style: AppTypography.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          NombreDeNomsField(
            value: _valeur,
            minimum: 0.5,
            onChanged: (valeur) => setState(() => _valeur = valeur),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: context.l10n.membersAssign,
            variant: AppButtonVariant.accent,
            onPressed: () => Navigator.of(context).pop(_valeur),
          ),
        ],
      ),
    );
  }
}
