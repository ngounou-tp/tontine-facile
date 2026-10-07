import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_form.dart' show messageErreurAuth;
import '../widgets/auth_header.dart';

/// Ouvert par le lien de réinitialisation reçu par email : la session est
/// temporaire tant qu'un nouveau mot de passe n'a pas été choisi.
class NouveauMotDePassePage extends ConsumerStatefulWidget {
  const NouveauMotDePassePage({super.key});

  @override
  ConsumerState<NouveauMotDePassePage> createState() => _NouveauMotDePassePageState();
}

class _NouveauMotDePassePageState extends ConsumerState<NouveauMotDePassePage> {
  final _formKey = GlobalKey<FormState>();
  final _motDePasse = TextEditingController();
  final _confirmation = TextEditingController();
  var _masque = true;

  @override
  void dispose() {
    _motDePasse.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authControllerProvider.notifier).changerMotDePasse(_motDePasse.text);
      if (!mounted) return;
      ref.read(flashMessageProvider.notifier).set(context.l10n.newPasswordSaved);
      context.go(AppRouter.rootPath);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(authControllerProvider).isLoading;
    final bascule = IconButton(
      onPressed: () => setState(() => _masque = !_masque),
      icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined),
      tooltip: l10n.authTogglePasswordVisibility,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(l10n.newPasswordTitle, style: AppTypography.screenTitle),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.authPasswordLabel, style: AppTypography.bodyStrong),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _motDePasse,
                      obscureText: _masque,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (valeur) =>
                          (valeur?.length ?? 0) < 6 ? l10n.authPasswordTooShort : null,
                      decoration: InputDecoration(suffixIcon: bascule),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.authConfirmPasswordLabel, style: AppTypography.bodyStrong),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _confirmation,
                      obscureText: _masque,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => busy ? null : _enregistrer(),
                      validator: (valeur) =>
                          valeur != _motDePasse.text ? l10n.authPasswordsDoNotMatch : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: l10n.newPasswordSubmit,
                      variant: AppButtonVariant.accent,
                      busy: busy,
                      onPressed: busy ? null : _enregistrer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
