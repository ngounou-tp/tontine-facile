import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/adhesion.dart';
import '../../../../l10n/domain_labels.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/tontine_logo.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;

/// Tous les groupes du compte, avec ses rôles dans chacun : on passe de
/// l'un à l'autre d'un geste, on en crée ou on en rejoint un nouveau.
class MesGroupesPage extends ConsumerWidget {
  const MesGroupesPage({super.key});

  Future<void> _choisir(BuildContext context, WidgetRef ref, Adhesion adhesion) async {
    try {
      await ref.read(authControllerProvider.notifier).choisirGroupe(adhesion.groupeId);
      if (context.mounted) context.go(AppRouter.rootPath);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sessionAsync = ref.watch(sessionProvider);
    final session = sessionAsync.value;
    final courant = session?.profil?.tontineId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.commonBack,
          onPressed: () => context.go(AppRouter.rootPath),
        ),
        title: Text(l10n.groupsTitle),
      ),
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: messageErreurAuth(error),
            onRetry: () => ref.invalidate(sessionProvider),
          ),
          data: (_) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(l10n.groupsSubtitle, style: AppTypography.secondary),
              const SizedBox(height: AppSpacing.md),
              for (final adhesion in session?.adhesions ?? const <Adhesion>[]) ...[
                _CarteGroupe(
                  adhesion: adhesion,
                  courant: adhesion.groupeId == courant,
                  onTap: () => _choisir(context, ref, adhesion),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.welcomeCreateTitle,
                icon: Icons.add_circle_outline,
                variant: AppButtonVariant.accent,
                onPressed: () => context.go(AppRouter.creerTontinePath),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: l10n.groupsJoinWithCode,
                icon: Icons.qr_code_2_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(AppRouter.rejoindrePath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteGroupe extends StatelessWidget {
  const _CarteGroupe({required this.adhesion, required this.courant, required this.onTap});

  final Adhesion adhesion;
  final bool courant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roles = adhesion.roles.toList()..sort((a, b) => a.index.compareTo(b.index));
    return Semantics(
      selected: courant,
      button: true,
      child: AppCard(
        onTap: onTap,
        borderColor: courant ? AppColors.indigo : null,
        child: Row(
          children: [
            const TontineLogo(size: 40),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(adhesion.nomGroupe, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis),
                  Text(
                    roles.map((role) => role.label(l10n)).join(' · '),
                    style: AppTypography.secondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (courant)
              AppPill(label: l10n.groupsCurrent, tone: AppTone.info)
            else
              const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
      ),
    );
  }
}
