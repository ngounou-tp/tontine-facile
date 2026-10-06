import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../l10n/l10n.dart';

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

  /// La touche « Terminé » du clavier valide le formulaire : pas besoin de
  /// fermer le clavier pour aller chercher le bouton.
  void _soumettreDepuisClavier() {
    if (!widget.busy) widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.l10n.authEmailLabel, style: AppTypography.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(controller: widget.emailController, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], textInputAction: TextInputAction.next, validator: (value) => _emailValidator(context, value)),
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.authPasswordLabel, style: AppTypography.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(controller: widget.passwordController, obscureText: _hidePassword, autofillHints: const [AutofillHints.password], textInputAction: widget.confirmPasswordController == null ? TextInputAction.done : TextInputAction.next, onFieldSubmitted: widget.confirmPasswordController == null ? (_) => _soumettreDepuisClavier() : null, validator: (value) => _passwordValidator(context, value), decoration: InputDecoration(suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), tooltip: context.l10n.authTogglePasswordVisibility))),
        if (widget.confirmPasswordController case final confirmation?) ...[
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.authConfirmPasswordLabel, style: AppTypography.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(controller: confirmation, obscureText: _hideConfirmation, autofillHints: const [AutofillHints.newPassword], textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _soumettreDepuisClavier(), validator: (value) => value != widget.passwordController.text ? context.l10n.authPasswordsDoNotMatch : null, decoration: InputDecoration(suffixIcon: IconButton(onPressed: () => setState(() => _hideConfirmation = !_hideConfirmation), icon: Icon(_hideConfirmation ? Icons.visibility_outlined : Icons.visibility_off_outlined), tooltip: context.l10n.authTogglePasswordVisibility))),
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

String? _emailValidator(BuildContext context, String? value) {
  final email = value?.trim() ?? '';
  return email.isEmpty || !email.contains('@') ? context.l10n.authInvalidEmail : null;
}

String? _passwordValidator(BuildContext context, String? value) =>
    (value?.length ?? 0) < 6 ? context.l10n.authPasswordTooShort : null;

String messageErreurAuth(Object error) => switch (error) {
  AppException(:final message) => message,
  _ => L10n.current.errorGeneric,
};
