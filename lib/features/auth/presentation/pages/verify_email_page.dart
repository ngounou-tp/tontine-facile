import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_form.dart';

/// Écran affiché tant que l'email de l'utilisateur n'est pas vérifié
/// (uniquement imposé en environnement live — voir `AppRouter.redirect`).
///
/// Revérifie automatiquement toutes les 5 secondes (au cas où le lien a été
/// ouvert dans un autre onglet) et propose de renvoyer l'email ou de
/// vérifier manuellement.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  Timer? _sondage;
  Timer? _compteARebours;
  int _secondesAvantRenvoi = 0;

  @override
  void initState() {
    super.initState();
    _sondage = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _verifier(silencieux: true),
    );
  }

  @override
  void dispose() {
    _sondage?.cancel();
    _compteARebours?.cancel();
    super.dispose();
  }

  Future<void> _verifier({bool silencieux = false}) async {
    try {
      final verifie =
          await ref.read(authControllerProvider.notifier).verifierEmailVerifie();
      if (verifie) {
        ref.invalidate(sessionProvider);
      } else if (!silencieux && mounted) {
        _message(
          'Toujours pas vérifié. Pensez à vérifier vos courriers indésirables.',
        );
      }
    } catch (error) {
      if (!silencieux && mounted) _message(messageErreurAuth(error));
    }
  }

  Future<void> _renvoyer() async {
    if (_secondesAvantRenvoi > 0) return;
    try {
      await ref.read(authControllerProvider.notifier).renvoyerEmailVerification();
      if (mounted) _message('Email de vérification renvoyé.');
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
    final email =
        ref.watch(sessionProvider).value?.utilisateur.email ?? 'votre adresse';

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
                const Text(
                  'Vérifiez votre adresse email',
                  textAlign: TextAlign.center,
                  style: AppTypography.screenTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Un lien de vérification a été envoyé à $email. '
                  'Ouvrez-le, puis revenez sur cet écran.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: "J'ai vérifié mon adresse",
                    variant: AppButtonVariant.accent,
                    busy: busy,
                    onPressed: busy ? null : () => _verifier(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _secondesAvantRenvoi > 0
                        ? "Renvoyer l'email ($_secondesAvantRenvoi s)"
                        : "Renvoyer l'email",
                    variant: AppButtonVariant.secondary,
                    onPressed:
                        (busy || _secondesAvantRenvoi > 0) ? null : _renvoyer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Se déconnecter',
                  variant: AppButtonVariant.tertiary,
                  onPressed: busy
                      ? null
                      : () => ref.read(authControllerProvider.notifier).deconnecter(),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
