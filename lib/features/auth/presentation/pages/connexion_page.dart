import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_header.dart';
import '../../../../l10n/l10n.dart';

class ConnexionPage extends ConsumerStatefulWidget {
  const ConnexionPage({super.key});

  @override
  ConsumerState<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends ConsumerState<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authControllerProvider.notifier).connecter(
            email: _email.text.trim(),
            password: _password.text,
          );
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  Future<void> _continuerAvecGoogle() async {
    try {
      final session =
          await ref.read(authControllerProvider.notifier).connecterAvecGoogle();
      // `session == null` : l'utilisateur a annulé la sélection de compte,
      // ce n'est pas une erreur à signaler.
      if (session == null) return;
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  Future<void> _reinitialiserMotDePasse() async {
    if (!_email.text.contains('@')) {
      _message(context.l10n.loginEnterEmailForReset);
      return;
    }
    try {
      await ref.read(authControllerProvider.notifier).reinitialiserMotDePasse(_email.text.trim());
      if (mounted) _message(context.l10n.loginResetLinkSent);
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const AuthHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  AuthForm(
                    formKey: _formKey,
                    emailController: _email,
                    passwordController: _password,
                    submitLabel: context.l10n.loginSubmit,
                    onSubmit: _connecter,
                    busy: busy,
                    extraBeforeSubmit: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: busy ? null : _reinitialiserMotDePasse,
                        child: Text(context.l10n.loginForgotPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(context.l10n.commonOr, style: AppTypography.secondary),
                      ),
                      const Expanded(child: Divider(color: AppColors.line)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: busy ? null : _continuerAvecGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.indigo),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/google_logo.png', width: 20, height: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Text(context.l10n.loginContinueWithGoogle),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: context.l10n.loginCreateAccount,
                    variant: AppButtonVariant.tertiary,
                    onPressed: busy ? null : () => context.go(AppRouter.inscriptionPath),
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
