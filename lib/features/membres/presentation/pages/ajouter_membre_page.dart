import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/invitation.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_controller.dart';
import '../widgets/membre_form.dart';

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
          .showSnackBar(const SnackBar(content: Text('Code copié.')));
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
          tooltip: 'Retour',
          onPressed: () => context.go(AppRouter.membresPath),
        ),
        title: const Text('Ajouter un membre'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: invitation == null
                ? MembreForm(
                    submitLabel: 'Ajouter et générer le code',
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
                      ref.read(flashMessageProvider.notifier).set(
                          '$_nomAjoute a été ajouté(e) à la tontine.');
                      context.go(AppRouter.membresPath);
                    },
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

  String _libelleNoms() {
    final entier = nombreDeNoms.truncate();
    final demi = nombreDeNoms - entier >= 0.5 - 1e-9;
    if (nombreDeNoms <= 0) return 'sans nom attribué pour le moment';
    if (entier == 0 && demi) return 'avec ½ nom';
    if (!demi) return 'avec $entier nom${entier > 1 ? 's' : ''}';
    return 'avec $entier½ noms';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('$nomComplet a été ajouté(e)', style: AppTypography.screenTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_libelleNoms()[0].toUpperCase()}${_libelleNoms().substring(1)}. '
          'Transmettez-lui ce code pour qu\'il ou elle rejoigne la tontine.',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  invitation.code,
                  style: AppTypography.pageTitle.copyWith(letterSpacing: 6),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Copier le code',
                  icon: Icons.copy_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: onCopier,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Terminé', variant: AppButtonVariant.accent, onPressed: onTermine),
      ],
    );
  }
}
