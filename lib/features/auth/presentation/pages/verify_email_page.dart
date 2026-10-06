import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../widgets/auth_form.dart';
import '../../../../l10n/l10n.dart';

/// Écran affiché tant que l'email de l'utilisateur n'est pas vérifié
/// (uniquement imposé en environnement live — voir `AppRouter.redirect`).
///
/// Revérifie automatiquement toutes les 5 secondes (au cas où le lien a été
/// ouvert dans un autre onglet) et propose de renvoyer l'email ou de
/// vérifier manuellement.
/// Après une inscription par email : « ouvrez le lien reçu ». Aucune
/// session n'existe encore — elle s'ouvrira à l'ouverture du lien sur ce
/// téléphone (retour automatique dans l'app), ou en se connectant ensuite.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({this.email, super.key});

  /// Adresse utilisée à l'inscription (affichée, et cible du renvoi).
  final String? email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  Timer? _compteARebours;
  int _secondesAvantRenvoi = 0;

  @override
  void dispose() {
    _compteARebours?.cancel();
    super.dispose();
  }

  Future<void> _renvoyer() async {
    final email = widget.email;
    if (_secondesAvantRenvoi > 0 || email == null) return;
    try {
      await ref.read(authControllerProvider.notifier).renvoyerConfirmation(email);
      if (mounted) _message(context.l10n.verifyEmailResent);
      _demarrerCompteARebours();
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  void _demarrerCompteARebours() {
    setState(() => _secondesAvantRenvoi = 30);
    _compteARebours?.cancel();
    _compteARebours = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondesAvantRenvoi -= 1;
        if (_secondesAvantRenvoi <= 0) timer.cancel();
      });
    });
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    final email = widget.email ?? context.l10n.verifyYourAddressFallback;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(children: [
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppColors.indigo,
                    size: 44,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.l10n.verifyTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.screenTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.verifyBodyLink(email),
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: context.l10n.verifyDoneSignIn,
                    variant: AppButtonVariant.accent,
                    onPressed: () => context.go(AppRouter.connexionPath),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _secondesAvantRenvoi > 0
                        ? context.l10n.verifyResendIn(_secondesAvantRenvoi)
                        : context.l10n.verifyResend,
                    variant: AppButtonVariant.secondary,
                    onPressed:
                        (busy || _secondesAvantRenvoi > 0 || widget.email == null) ? null : _renvoyer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: context.l10n.commonBack,
                  variant: AppButtonVariant.tertiary,
                  onPressed: () => context.go(AppRouter.connexionPath),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
