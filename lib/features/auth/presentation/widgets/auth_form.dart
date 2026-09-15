import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/app_button.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({required this.formKey, required this.emailController, required this.passwordController, required this.submitLabel, required this.onSubmit, this.confirmPasswordController, this.extraBeforeSubmit, this.busy = false, super.key});

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? confirmPasswordController;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget? extraBeforeSubmit;
  final bool busy;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(controller: widget.emailController, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], textInputAction: TextInputAction.next, validator: _emailValidator),
        const SizedBox(height: AppSpacing.md),
        const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(controller: widget.passwordController, obscureText: _hidePassword, autofillHints: const [AutofillHints.password], textInputAction: widget.confirmPasswordController == null ? TextInputAction.done : TextInputAction.next, validator: _passwordValidator, decoration: InputDecoration(suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), tooltip: 'Afficher ou masquer le mot de passe'))),
        if (widget.confirmPasswordController case final confirmation?) ...[
          const SizedBox(height: AppSpacing.md),
          const Text('Confirmer le mot de passe', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(controller: confirmation, obscureText: _hideConfirmation, autofillHints: const [AutofillHints.newPassword], textInputAction: TextInputAction.done, validator: (value) => value != widget.passwordController.text ? 'Les mots de passe ne correspondent pas.' : null, decoration: InputDecoration(suffixIcon: IconButton(onPressed: () => setState(() => _hideConfirmation = !_hideConfirmation), icon: Icon(_hideConfirmation ? Icons.visibility_outlined : Icons.visibility_off_outlined), tooltip: 'Afficher ou masquer le mot de passe'))),
        ],
        if (widget.extraBeforeSubmit case final extra?) ...[
          const SizedBox(height: AppSpacing.xs),
          extra,
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: widget.submitLabel, variant: AppButtonVariant.accent, busy: widget.busy, onPressed: widget.busy ? null : widget.onSubmit),
      ]),
    );
  }
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  return email.isEmpty || !email.contains('@') ? 'Saisissez une adresse e-mail valide.' : null;
}

String? _passwordValidator(String? value) => (value?.length ?? 0) < 6 ? 'Le mot de passe doit contenir au moins 6 caractères.' : null;

String messageErreurAuth(Object error) => switch (error) {
  AppException(:final message) => message,
  _ => 'Une erreur est survenue. Réessayez.',
};
