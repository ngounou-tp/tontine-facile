import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/rules/validation_parts.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/member_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../echeancier/application/echeancier_controller.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_providers.dart';
import '../widgets/nombre_de_noms_field.dart' show formatterNombreDeNoms;
import '../widgets/parts_editor.dart';
import '../../../../l10n/l10n.dart';

/// Liste des membres et des noms de la tontine courante, avec les actions
/// d'ajout, d'attribution des parts et de génération de l'échéancier une
/// fois tous les noms répartis.
class MembresPage extends ConsumerWidget {
  const MembresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlashMessageListener.attach(ref, context);
    final membresAsync = ref.watch(membresProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final noms = nomsAsync.value ?? const [];
    final membres = membresAsync.value ?? const [];
    final isAdmin = ref.watch(isAdminProvider);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        selectedNavIndex: 1,
        appBar: AppBar(
          title: Text(context.l10n.membersTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.membersTabNames(noms.length)),
              Tab(text: context.l10n.membersTabMembers(membres.length)),
            ],
          ),
        ),
        floatingActionButton: !isAdmin
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.go('${AppRouter.membresPath}/ajouter'),
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.ink,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.commonAdd),
              ),
        body: membresAsync.hasError || nomsAsync.hasError
            ? ErrorView(
                message: context.l10n.membersLoadError,
                onRetry: () {
                  ref.invalidate(membresProvider);
                  ref.invalidate(nomsProvider);
                },
              )
            : (membresAsync.isLoading || nomsAsync.isLoading) &&
                    !membresAsync.hasValue &&
                    !nomsAsync.hasValue
                ? const LoadingView()
                : _Contenu(membres: membres, noms: noms, isAdmin: isAdmin),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.membres, required this.noms, required this.isAdmin});

  final List<Membre> membres;
  final List<Nom> noms;
  final bool isAdmin;

  double _totalParts(String membreId) {
    var total = 0.0;
    for (final nom in noms) {
      for (final part in nom.parts) {
        if (part.membreId == membreId) total += part.fraction;
      }
    }
    return total;
  }

  Future<void> _genererEcheancier(BuildContext context, WidgetRef ref) async {
    final tontine = ref.read(tontineProvider).value;
    if (tontine == null) return;
    try {
      await ref
          .read(echeancierControllerProvider.notifier)
          .genererEcheancier(tontine: tontine, noms: noms);
      if (context.mounted) context.go(AppRouter.accueilPath);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tours = ref.watch(toursProvider).value ?? const [];
    final tontine = ref.watch(tontineProvider).value;
    final busyEcheancier = ref.watch(echeancierControllerProvider).isLoading;

    final actifs = membres.where((m) => m.actif).toList(growable: false);
    final inactifs = membres.where((m) => !m.actif).toList(growable: false);

    final tousLesNomsValides = noms.isNotEmpty &&
        noms.every((nom) => const ValidationParts().estValide(nom.parts));
    final quotaAtteint = tontine != null && noms.length >= tontine.nombreDeNoms;
    final peutGenerer = tousLesNomsValides && quotaAtteint && tours.isEmpty;

    return SafeArea(
      child: TabBarView(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
            children: [
              if (tontine != null) ...[
                _AvancementNoms(attribues: noms.length, attendus: tontine.nombreDeNoms),
                const SizedBox(height: AppSpacing.md),
              ],
              SectionHeader(
                title: context.l10n.membersSectionNames,
                actionLabel: isAdmin && !quotaAtteint && noms.isNotEmpty ? context.l10n.membersAssign : null,
                actionIcon: Icons.add,
                onAction: () => context.go('${AppRouter.membresPath}/noms/nouveau'),
              ),
              if (noms.isEmpty)
                EmptyState(
                  compact: true,
                  icon: Icons.badge_outlined,
                  message: context.l10n.membersNoNamesYet,
                  actionLabel: isAdmin ? context.l10n.membersAssignName : null,
                  onAction: isAdmin ? () => context.go('${AppRouter.membresPath}/noms/nouveau') : null,
                )
              else
                ...noms.map(
                  (nom) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _NomCard(
                      nom: nom,
                      membres: membres,
                      onTap: !isAdmin
                          ? null
                          : () => context.go('${AppRouter.membresPath}/noms/${nom.id}'),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (isAdmin && peutGenerer)
                AppButton(
                  label: context.l10n.membersGenerateSchedule,
                  icon: Icons.event_available_outlined,
                  variant: AppButtonVariant.accent,
                  busy: busyEcheancier,
                  onPressed: busyEcheancier ? null : () => _genererEcheancier(context, ref),
                )
              else if (isAdmin && tousLesNomsValides && !quotaAtteint && tours.isEmpty && tontine != null)
                EmptyState(
                  compact: true,
                  icon: Icons.event_available_outlined,
                  message: context.l10n.membersNamesLeftBeforeSchedule(tontine.nombreDeNoms - noms.length),
                ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
            children: [
              SectionHeader(title: context.l10n.membersActiveSection(actifs.length)),
              if (actifs.isEmpty)
                EmptyState(
                  compact: true,
                  icon: Icons.person_add_alt_1_outlined,
                  message: context.l10n.membersNoActive,
                  actionLabel: isAdmin ? context.l10n.addMemberTitle : null,
                  onAction: isAdmin ? () => context.go('${AppRouter.membresPath}/ajouter') : null,
                )
              else
                ...actifs.map(
                  (membre) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MembreCard(
                      membre: membre,
                      totalParts: _totalParts(membre.id),
                      onTap: () => context.go('${AppRouter.membresPath}/${membre.id}'),
                    ),
                  ),
                ),
              if (inactifs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: context.l10n.membersInactiveSection(inactifs.length)),
                ...inactifs.map(
                  (membre) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MembreCard(
                      membre: membre,
                      totalParts: _totalParts(membre.id),
                      onTap: () => context.go('${AppRouter.membresPath}/${membre.id}'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NomCard extends StatelessWidget {
  const _NomCard({required this.nom, required this.membres, required this.onTap});

  final Nom nom;
  final List<Membre> membres;
  final VoidCallback? onTap;

  String _nomComplet(String membreId) {
    for (final membre in membres) {
      if (membre.id == membreId) return membre.nomComplet;
    }
    return L10n.current.unknownMember;
  }

  @override
  Widget build(BuildContext context) {
    final sommeValide = const ValidationParts().estValide(nom.parts);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Text('${nom.position}', style: AppTypography.bodyStrong.copyWith(color: AppColors.indigo)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom.libelle, style: AppTypography.bodyStrong),
                Text(
                  nom.parts.isEmpty
                      ? context.l10n.membersNoHolder
                      : nom.parts
                          .map((p) => '${formatFraction(p.fraction)} ${_nomComplet(p.membreId)}')
                          .join(', '),
                  style: AppTypography.secondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!sommeValide)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: AppPill(label: context.l10n.membersToComplete, tone: AppTone.danger),
            ),
          if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.slate),
        ],
      ),
    );
  }
}

class _MembreCard extends StatelessWidget {
  const _MembreCard({required this.membre, required this.totalParts, required this.onTap});

  final Membre membre;
  final double totalParts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enAttente = membre.uid == null;
    return Opacity(
      // Membre désactivé : estompé, mais toujours lisible et ouvrable.
      opacity: membre.actif ? 1 : 0.6,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            MemberAvatar(nomComplet: membre.nomComplet),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(membre.nomComplet, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis),
                  Text(
                    membre.whatsapp ?? membre.email ?? context.l10n.membersNoContact,
                    style: AppTypography.secondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppPill(label: formatterNombreDeNoms(totalParts), tone: AppTone.info),
                if (enAttente) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  AppPill(label: context.l10n.membersPending, tone: AppTone.warning),
                ],
              ],
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
      ),
    );
  }
}

/// Jauge « noms attribués / attendus » en tête de l'onglet Noms : tant
/// qu'elle n'est pas pleine, l'échéancier ne peut pas être généré.
class _AvancementNoms extends StatelessWidget {
  const _AvancementNoms({required this.attribues, required this.attendus});

  final int attribues;
  final int attendus;

  @override
  Widget build(BuildContext context) {
    final complet = attendus > 0 && attribues >= attendus;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$attribues', style: AppTypography.amount.copyWith(fontWeight: FontWeight.w600)),
              Text(context.l10n.membersNamesAssignedOf(attendus), style: AppTypography.secondary),
              const Spacer(),
              if (complet) AppPill(label: context.l10n.membersComplete, tone: AppTone.success),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: attendus == 0 ? 0 : attribues / attendus,
            color: complet ? AppColors.success : AppColors.indigo,
          ),
        ],
      ),
    );
  }
}
