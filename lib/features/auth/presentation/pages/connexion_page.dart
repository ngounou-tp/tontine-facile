import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_header.dart';

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
      _message('Saisissez votre e-mail pour recevoir le lien de réinitialisation.');
      return;
    }
    try {
      await ref.read(authControllerProvider.notifier).reinitialiserMotDePasse(_email.text.trim());
      if (mounted) _message('Un lien de réinitialisation a été envoyé à votre adresse e-mail.');
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
              child: Column(children: [
                const SizedBox(height: AppSpacing.xl),
                const AuthHeader(),
                const SizedBox(height: AppSpacing.xl),
                AuthForm(
                  formKey: _formKey,
                  emailController: _email,
                  passwordController: _password,
                  submitLabel: 'Se connecter',
                  onSubmit: _connecter,
                  busy: busy,
                  extraBeforeSubmit: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : _reinitialiserMotDePasse,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('— ou —', textAlign: TextAlign.center, style: AppTypography.secondary),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: busy ? null : _continuerAvecGoogle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/google_logo.png', width: 20, height: 20),
                        const SizedBox(width: AppSpacing.xs),
                        const Text('Continuer avec Google'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: 'Créer un compte', variant: AppButtonVariant.tertiary, onPressed: busy ? null : () => context.go(AppRouter.inscriptionPath)),
                const SizedBox(height: AppSpacing.lg),
                InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                  onTap: busy ? null : () => context.go(AppRouter.rejoindrePath),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      'Vous rejoignez une tontine existante ?\nUn code vous a été remis par votre trésorier.',
                      textAlign: TextAlign.center,
                      style: AppTypography.secondary,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
