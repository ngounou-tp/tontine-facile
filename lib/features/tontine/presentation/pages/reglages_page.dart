import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/application/auth_providers.dart';

/// Onglet Réglages : menu des paramètres de l'application (tontine, profil
/// utilisateur...) et actions de compte.
class ReglagesPage extends ConsumerWidget {
  const ReglagesPage({super.key});

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
    final session = ref.watch(sessionProvider).value;
    final membreId = session?.profil?.membreId;
    final isAdmin = ref.watch(isAdminProvider);

    return AppScaffold(
      selectedNavIndex: 4,
      appBar: AppBar(title: const Text('Réglages')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _EnTeteSection('Groupe'),
            _CarteMenu(
              icon: Icons.groups_outlined,
              title: 'Réglages de la tontine',
              subtitle: isAdmin
                  ? 'Nom, montant, pénalité, nombre de noms'
                  : 'Consulter (lecture seule)',
              onTap: () => context.go('${AppRouter.reglagesPath}/tontine'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _EnTeteSection('Compte'),
            _CarteMenu(
              icon: Icons.person_outline,
              title: 'Mon profil',
              subtitle: isAdmin
                  ? 'Vos coordonnées et votre code d\'invitation'
                  : 'Vos noms, vos cotisations et vos déclarations',
              onTap: isAdmin
                  ? (membreId == null ? null : () => context.go('${AppRouter.membresPath}/$membreId'))
                  : () => context.go(AppRouter.espaceMembrePath),
            ),
            const SizedBox(height: AppSpacing.xl),
            _CarteMenu(
              icon: Icons.logout,
              title: 'Se déconnecter',
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
      ),
    );
  }
}
