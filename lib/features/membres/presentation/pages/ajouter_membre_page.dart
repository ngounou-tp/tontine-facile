import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/invitation.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_controller.dart';
import '../widgets/membre_form.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/nombre_de_noms_field.dart' show formatterNombreDeNoms;

/// Ajoute un nouveau membre (placeholder, sans compte) et lui génère aussitôt
/// un code d'invitation à transmettre — l'ajout et la génération du code
/// forment un seul geste pour l'administratrice.
class AjouterMembrePage extends ConsumerStatefulWidget {
  const AjouterMembrePage({super.key});

  @override
  ConsumerState<AjouterMembrePage> createState() => _AjouterMembrePageState();
}

class _AjouterMembrePageState extends ConsumerState<AjouterMembrePage> {
  Invitation? _invitation;
  String? _nomAjoute;
  double _nombreDeNomsAjoute = 0;

  Future<void> _ajouter(MembreFormValue valeur) async {
    final tontineId = ref.read(currentTontineIdProvider);
    if (tontineId == null) return;
    try {
      final invitation =
          await ref.read(membresControllerProvider.notifier).inviterMembreAvecNoms(
                tontineId: tontineId,
                nomComplet: valeur.nomComplet,
                email: valeur.email,
                whatsapp: valeur.whatsapp,
                nombreDeNoms: valeur.nombreDeNoms,
              );
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _invitation = invitation;
          _nomAjoute = valeur.nomComplet;
          _nombreDeNomsAjoute = valeur.nombreDeNoms;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  Future<void> _copierCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.addMemberCodeCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(membresControllerProvider).isLoading;
    final invitation = _invitation;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.commonBack,
          onPressed: () => context.go(AppRouter.membresPath),
        ),
        title: Text(context.l10n.addMemberTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            // Fondu entre le formulaire et la confirmation, plutôt qu'un
            // remplacement sec.
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.easeOut,
              child: invitation == null
                ? MembreForm(
                    submitLabel: context.l10n.addMemberSubmit,
                    busy: busy,
                    afficherNombreDeNoms: true,
                    onSubmit: _ajouter,
                  )
                : _Confirmation(
                    nomComplet: _nomAjoute!,
                    nombreDeNoms: _nombreDeNomsAjoute,
                    invitation: invitation,
                    onCopier: () => _copierCode(invitation.code),
                    onTermine: () {
                      ref.read(flashMessageProvider.notifier).set(context.l10n.addMemberAddedFlash(_nomAjoute!));
                      context.go(AppRouter.membresPath);
                    },
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.nomComplet,
    required this.nombreDeNoms,
    required this.invitation,
    required this.onCopier,
    required this.onTermine,
  });

  final String nomComplet;
  final double nombreDeNoms;
  final Invitation invitation;
  final VoidCallback onCopier;
  final VoidCallback onTermine;

  String _libelleNoms(AppLocalizations l10n) => nombreDeNoms <= 0
      ? l10n.addMemberNoNamesYet
      : l10n.addMemberWithNames(formatterNombreDeNoms(nombreDeNoms));

  @override
  Widget build(BuildContext context) {
    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        // Moment de réussite : la coche « éclot » (0,6 → 1 avec un léger
        // dépassement) au lieu d'être simplement là. Jamais depuis 0 :
        // rien n'apparaît de nulle part.
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduireAnimations ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
            ),
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.addMemberAddedTitle(nomComplet),
          textAlign: TextAlign.center,
          style: AppTypography.screenTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_libelleNoms(context.l10n)} ${context.l10n.addMemberShareCode}',
          textAlign: TextAlign.center,
          style: AppTypography.secondary,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(context.l10n.addMemberInviteCodeOverline, style: AppTypography.overline),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                label: context.l10n.addMemberInviteCodeSemantics(invitation.code.split('').join(' ')),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final caractere in invitation.code.split(''))
                        Container(
                          width: 40,
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: Text(caractere, style: AppTypography.screenTitle),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: context.l10n.addMemberCopyCode,
                icon: Icons.copy_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: onCopier,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: context.l10n.commonDone, variant: AppButtonVariant.accent, onPressed: onTermine),
      ],
    );
  }
}
