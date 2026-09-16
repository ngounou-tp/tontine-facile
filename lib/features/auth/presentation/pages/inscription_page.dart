import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_header.dart';

class InscriptionPage extends ConsumerStatefulWidget {
  const InscriptionPage({this.codeInvitation, super.key});

  /// Code saisi sur l'écran d'adhésion avant d'avoir de compte : une fois le
  /// compte créé, il sert à réclamer directement le membre invité plutôt que
  /// de créer un compte "orphelin" (voir [InscriptionService.inscrireMembre]).
  final String? codeInvitation;

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends ConsumerState<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final code = widget.codeInvitation;
      if (code != null) {
        await ref.read(authControllerProvider.notifier).inscrireMembre(
              email: _email.text.trim(),
              password: _password.text,
              codeInvitation: code,
            );
        if (mounted) context.go(AppRouter.espaceMembrePath);
      } else {
        await ref.read(authControllerProvider.notifier).creerCompteSansTontine(
              email: _email.text.trim(),
              password: _password.text,
            );
        if (mounted) context.go(AppRouter.choixPath);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Retour', onPressed: () => context.go(AppRouter.connexionPath))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(children: [
                const AuthHeader(),
                const SizedBox(height: AppSpacing.lg),
                Text('Créer un compte', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                AuthForm(formKey: _formKey, emailController: _email, passwordController: _password, confirmPasswordController: _confirmation, submitLabel: 'Créer mon compte', onSubmit: _inscrire, busy: busy),
                AppButton(label: 'J’ai déjà un compte', variant: AppButtonVariant.tertiary, onPressed: busy ? null : () => context.go(AppRouter.connexionPath)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
