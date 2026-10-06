import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/locale_controller.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../../l10n/l10n.dart';

/// Onglet Réglages : menu des paramètres de l'application (tontine, profil
/// utilisateur...) et actions de compte.
class ReglagesPage extends ConsumerWidget {
  const ReglagesPage({super.key});

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

  String _nomLangue(AppLocalizations l10n, Locale? langue) => switch (langue?.languageCode) {
        'fr' => l10n.languageFrench,
        'en' => l10n.languageEnglish,
        _ => l10n.settingsLanguageSystem,
      };

  /// Feuille de choix : langue du téléphone (par défaut), français, anglais.
  Future<void> _choisirLangue(BuildContext context, WidgetRef ref, Locale? actuelle) async {
    final l10n = context.l10n;
    final options = <(Locale?, String)>[
      (null, l10n.settingsLanguageSystem),
      (const Locale('fr'), l10n.languageFrench),
      (const Locale('en'), l10n.languageEnglish),
    ];
    final choix = await showModalBottomSheet<(Locale?,)>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (locale, libelle) in options)
              ListTile(
                title: Text(libelle),
                trailing: locale?.languageCode == actuelle?.languageCode
                    ? const Icon(Icons.check, color: AppColors.indigo)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop((locale,)),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (choix != null) {
      await ref.read(localeControllerProvider.notifier).setLocale(choix.$1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final membreId = session?.profil?.membreId;
    final isAdmin = ref.watch(isAdminProvider);
    final l10n = context.l10n;
    final langue = ref.watch(localeControllerProvider);

    return AppScaffold(
      selectedNavIndex: 4,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _EnTeteSection(l10n.settingsSectionGroup),
            _CarteMenu(
              icon: Icons.swap_horiz,
              title: l10n.settingsMyGroups,
              subtitle: l10n.settingsMyGroupsSubtitle(session?.adhesions.length ?? 1),
              onTap: () => context.go(AppRouter.groupesPath),
            ),
            const SizedBox(height: AppSpacing.sm),
            _CarteMenu(
              icon: Icons.groups_outlined,
              title: l10n.settingsTontineSettings,
              subtitle: isAdmin
                  ? l10n.settingsTontineSettingsAdmin
                  : l10n.settingsTontineSettingsMember,
              onTap: () => context.go('${AppRouter.reglagesPath}/tontine'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _EnTeteSection(l10n.settingsSectionAccount),
            _CarteMenu(
              icon: Icons.person_outline,
              title: l10n.settingsMyProfile,
              subtitle: isAdmin
                  ? l10n.settingsMyProfileAdmin
                  : l10n.settingsMyProfileMember,
              onTap: isAdmin
                  ? (membreId == null ? null : () => context.go('${AppRouter.membresPath}/$membreId'))
                  : () => context.go(AppRouter.espaceMembrePath),
            ),
            const SizedBox(height: AppSpacing.lg),
            _EnTeteSection(l10n.settingsSectionPreferences),
            _CarteMenu(
              icon: Icons.translate,
              title: l10n.settingsLanguage,
              subtitle: _nomLangue(l10n, langue),
              onTap: () => _choisirLangue(context, ref, langue),
            ),
            const SizedBox(height: AppSpacing.xl),
            _CarteMenu(
              icon: Icons.logout,
              title: l10n.commonSignOut,
              iconColor: AppColors.danger,
              titleColor: AppColors.danger,
              onTap: () => _confirmerDeconnexion(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnTeteSection extends StatelessWidget {
  const _EnTeteSection(this.titre);

  final String titre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(titre.toUpperCase(), style: AppTypography.micro),
    );
  }
}

class _CarteMenu extends StatelessWidget {
  const _CarteMenu({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = AppColors.indigo,
    this.titleColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTypography.secondary),
                    ],
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.slate),
            ],
          ),
      ),
    );
  }
}
