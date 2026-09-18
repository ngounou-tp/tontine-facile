import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../application/auth_controller.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_form.dart';

const _codeStyle = TextStyle(
  fontFamily: 'Sora',
  fontSize: 32,
  fontWeight: FontWeight.w600,
  color: AppColors.ink,
);

class RejoindreTontinePage extends ConsumerStatefulWidget {
  const RejoindreTontinePage({super.key});

  @override
  ConsumerState<RejoindreTontinePage> createState() => _RejoindreTontinePageState();
}

class _RejoindreTontinePageState extends ConsumerState<RejoindreTontinePage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  String get _code => _controllers.map((controller) => controller.text).join();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _rejoindre() async {
    if (_code.length != 6) {
      _message('Saisissez les 6 caractères du code d’invitation.');
      return;
    }

    final authentifie = ref.read(sessionProvider).value != null;
    if (!authentifie) {
      // Pas encore de compte : on le crée en réclamant directement ce code
      // (voir InscriptionPage.codeInvitation / InscriptionService.inscrireMembre).
      context.go(AppRouter.inscriptionPath, extra: _code);
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).rejoindreAvecCode(_code);
      if (mounted) {
        ref.read(flashMessageProvider.notifier).set('Vous avez rejoint la tontine.');
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  void _onCharacterChanged(int index, String value) {
    final character = value.toUpperCase();
    if (value != character) _controllers[index].value = TextEditingValue(text: character, selection: TextSelection.collapsed(offset: character.length));
    if (character.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    final authentifie = ref.watch(sessionProvider).value != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => context.go(authentifie ? AppRouter.choixPath : AppRouter.connexionPath),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Entrez votre code d’invitation',
                    textAlign: TextAlign.center,
                    style: AppTypography.screenTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Six caractères, remis par la trésorière du groupe.',
                    textAlign: TextAlign.center,
                    style: AppTypography.secondary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.indigo, width: 2),
                      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => Expanded(
                        child: SizedBox(
                          width: 48,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            enabled: !busy,
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            style: _codeStyle,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (value) => _onCharacterChanged(index, value),
                          ),
                        ),
                      )),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Clavier majuscules · collage autorisé', style: AppTypography.secondary),
                      Text('6 / 6', style: AppTypography.micro),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_code.length == 6) _ApercuTontine(code: _code),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(width: double.infinity, child: AppButton(label: 'Rejoindre', variant: AppButtonVariant.accent, busy: busy, onPressed: busy ? null : _rejoindre)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aperçu de la tontine visée par [code], résolu en direct via
/// [apercuInvitationProvider] au fur et à mesure de la saisie.
class _ApercuTontine extends ConsumerWidget {
  const _ApercuTontine({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apercu = ref.watch(apercuInvitationProvider(code));
    return apercu.when(
      loading: () => const _ApercuCard(
        icon: Icons.hourglass_top_outlined,
        label: Text('Recherche de la tontine…', style: AppTypography.body),
      ),
      error: (error, _) => _ApercuCard(
        icon: Icons.error_outline,
        iconColor: AppColors.danger,
        label: Text(messageErreurAuth(error), style: AppTypography.body),
      ),
      data: (value) => value == null
          ? _ApercuCard(
              icon: Icons.error_outline,
              iconColor: AppColors.danger,
              label: Text(
                const InvitationIntrouvableException().message,
                style: AppTypography.body,
              ),
            )
          : _ApercuCard(
              icon: Icons.groups_outlined,
              label: Text.rich(
                TextSpan(
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(text: value.nom),
                    TextSpan(
                      text: ' · ${value.nombreMembres} membres',
                      style: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ApercuCard extends StatelessWidget {
  const _ApercuCard({required this.icon, required this.label, this.iconColor = AppColors.ink});

  final IconData icon;
  final Color iconColor;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          CircleAvatar(backgroundColor: AppColors.canvas, child: Icon(icon, color: iconColor)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: label),
        ]),
      ),
    );
  }
}
