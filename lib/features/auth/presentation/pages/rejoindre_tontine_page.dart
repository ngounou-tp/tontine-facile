import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../l10n/l10n.dart';

const _longueurCode = 6;

class RejoindreTontinePage extends ConsumerStatefulWidget {
  const RejoindreTontinePage({super.key});

  @override
  ConsumerState<RejoindreTontinePage> createState() => _RejoindreTontinePageState();
}

class _RejoindreTontinePageState extends ConsumerState<RejoindreTontinePage> {
  // Un seul champ, rendu sous forme de six cases : le collage d'un code
  // reçu par WhatsApp et la touche Effacer fonctionnent naturellement, ce
  // qu'aucune rangée de six champs séparés ne permet.
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String get _code => _controller.text;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _rejoindre() async {
    if (_code.length != 6) {
      _message(context.l10n.joinEnterSixChars);
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
        ref.read(flashMessageProvider.notifier).set(L10n.current.joinSuccess);
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
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
          tooltip: context.l10n.commonBack,
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
                  Text(
                    context.l10n.joinTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.screenTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.joinSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.secondary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ChampCode(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !busy,
                    onChanged: (_) => setState(() {}),
                    onComplete: busy ? null : _rejoindre,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.l10n.joinPasteHint, style: AppTypography.secondary),
                      Text('${_code.length} / $_longueurCode', style: AppTypography.micro),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // L'aperçu du groupe apparaît dès le 6e caractère : on sait
                  // QUI on rejoint avant de valider.
                  AnimatedSize(
                    duration: AppMotion.medium,
                    curve: AppMotion.easeOut,
                    alignment: Alignment.topCenter,
                    child: _code.length == _longueurCode
                        ? _ApercuTontine(code: _code)
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: context.l10n.joinSubmit,
                      variant: AppButtonVariant.accent,
                      busy: busy,
                      onPressed: busy || _code.length != _longueurCode ? null : _rejoindre,
                    ),
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

/// Saisie d'un code à six caractères affichée en six cases. Un unique
/// [TextField] transparent, posé par-dessus les cases, reçoit le clavier :
/// collage, effacement et autoremplissage marchent comme dans un champ
/// normal. La case qui attend le prochain caractère est soulignée.
class _ChampCode extends StatelessWidget {
  const _ChampCode({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    this.onComplete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final code = controller.text;
        return Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < _longueurCode; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _CaseCode(
                      caractere: i < code.length ? code[i] : null,
                      active: focusNode.hasFocus &&
                          (i == code.length || (i == _longueurCode - 1 && code.length == _longueurCode)),
                    ),
                  ),
                ],
              ],
            ),
            Positioned.fill(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                showCursor: false,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(_longueurCode),
                  TextInputFormatter.withFunction(
                    (_, valeur) => valeur.copyWith(text: valeur.text.toUpperCase()),
                  ),
                ],
                // Texte invisible : seules les cases affichent les caractères.
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                ),
                onChanged: onChanged,
                onSubmitted: (_) {
                  if (controller.text.length == _longueurCode) onComplete?.call();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CaseCode extends StatelessWidget {
  const _CaseCode({required this.caractere, required this.active});

  final String? caractere;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final remplie = caractere != null;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: active ? AppColors.indigo : (remplie ? AppColors.ink.withValues(alpha: 0.35) : AppColors.line),
          width: active ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      ),
      // Chaque caractère arrive par un léger fondu + montée, pas d'un coup.
      child: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          caractere ?? '',
          key: ValueKey(caractere),
          style: AppTypography.screenTitle,
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
      loading: () => _ApercuCard(
        icon: Icons.hourglass_top_outlined,
        label: Text(context.l10n.joinSearching, style: AppTypography.body),
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
                      text: context.l10n.joinMembersCount(value.nombreMembres),
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
