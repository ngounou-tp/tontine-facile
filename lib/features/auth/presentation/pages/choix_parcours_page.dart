import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/tontine_logo.dart';
import '../../application/auth_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/l10n.dart';

/// Écran d'accueil du compte fraîchement créé (sans profil) : l'utilisateur
/// choisit entre créer une nouvelle tontine ou rejoindre un groupe existant
/// avec un code d'invitation.
///
/// Landing par défaut de `AppRouter.redirect` tant qu'aucune de ces deux
/// actions n'a abouti (voir `AppRouter._isNoProfileDestination`).
class ChoixParcoursPage extends ConsumerWidget {
  const ChoixParcoursPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: TontineLogo(size: 64),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(context.l10n.welcomeTitle(AppConstants.appName), style: AppTypography.screenTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.welcomeSubtitle,
                    style: AppTypography.secondary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _OptionCard(
                    icon: Icons.add_circle_outline,
                    iconBackground: AppColors.accent,
                    title: context.l10n.welcomeCreateTitle,
                    description: context.l10n.welcomeCreateDescription,
                    onTap: () => context.go(AppRouter.creerTontinePath),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OptionCard(
                    icon: Icons.groups_outlined,
                    iconBackground: AppColors.indigo,
                    title: context.l10n.welcomeJoinTitle,
                    description: context.l10n.welcomeJoinDescription,
                    onTap: () => context.go(AppRouter.rejoindrePath),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: AppButton(
                      label: context.l10n.commonSignOut,
                      variant: AppButtonVariant.tertiary,
                      onPressed: () => ref.read(authControllerProvider.notifier).deconnecter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Icon(icon, color: AppColors.surface, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(description, style: AppTypography.secondary),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(Icons.chevron_right, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}
