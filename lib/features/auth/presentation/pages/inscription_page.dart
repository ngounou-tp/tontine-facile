import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../../../../data/services/inscription_service.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_header.dart';
import '../../../../l10n/l10n.dart';

class InscriptionPage extends ConsumerStatefulWidget {
  const InscriptionPage({this.codeInvitation, super.key});

  /// Code saisi sur l'écran d'adhésion avant d'avoir de compte : une fois le
  /// compte créé, il sert à réclamer directement le membre invité plutôt que
  /// de créer un compte "orphelin" (voir [InscriptionService.inscrire]).
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
    final email = _email.text.trim();
    try {
      final issue = await ref.read(authControllerProvider.notifier).inscrire(
            email: email,
            password: _password.text,
            codeInvitation: widget.codeInvitation,
          );
      if (!mounted) return;
      switch (issue) {
        // Email à confirmer : aucune session tant que le lien n'est pas
        // ouvert. Le code d'invitation éventuel sera réclamé à la première
        // connexion (voir `InscriptionService.inscrire`).
        case IssueInscription.confirmationRequise:
          context.go(AppRouter.verifyEmailPath, extra: email);
        // Connecté : le routeur oriente selon les groupes du compte.
        case IssueInscription.connecte:
          context.go(widget.codeInvitation == null ? AppRouter.choixPath : AppRouter.rootPath);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: context.l10n.commonBack, onPressed: () => context.go(AppRouter.connexionPath))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(children: [
                const AuthHeader(),
                const SizedBox(height: AppSpacing.lg),
                Text(context.l10n.signupTitle, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                AuthForm(formKey: _formKey, emailController: _email, passwordController: _password, confirmPasswordController: _confirmation, submitLabel: context.l10n.signupSubmit, onSubmit: _inscrire, busy: busy),
                AppButton(label: context.l10n.signupHaveAccount, variant: AppButtonVariant.tertiary, onPressed: busy ? null : () => context.go(AppRouter.connexionPath)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
