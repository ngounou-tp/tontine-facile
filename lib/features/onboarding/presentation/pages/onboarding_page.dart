import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_pill.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/member_avatar.dart';
import '../../../../shared/widgets/tontine_logo.dart';
import '../../application/onboarding_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/l10n.dart';

/// Découverte de l'app au tout premier lancement : trois écrans qui
/// montrent, avec les vrais composants de l'app, ce qu'elle fait pour la
/// tontine — le cercle des tours, la collecte suivie au franc près, et les
/// déclarations de paiement validées par l'administratrice.
///
/// Affiché une seule fois par appareil (voir [onboardingVuProvider]) ;
/// « Passer » mène directement à la connexion.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _Etape {
  const _Etape({required this.titre, required this.texte, required this.illustration});

  final String Function(AppLocalizations l10n) titre;
  final String Function(AppLocalizations l10n) texte;
  final Widget illustration;
}

final _etapes = [
  _Etape(
    titre: (l10n) => l10n.onboarding1Title,
    texte: (l10n) => l10n.onboarding1Text(AppConstants.appName),
    illustration: _IllustrationCercle(),
  ),
  _Etape(
    titre: (l10n) => l10n.onboarding2Title,
    texte: (l10n) => l10n.onboarding2Text,
    illustration: _IllustrationCollecte(),
  ),
  _Etape(
    titre: (l10n) => l10n.onboarding3Title,
    texte: (l10n) => l10n.onboarding3Text,
    illustration: _IllustrationDeclaration(),
  ),
];

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  var _page = 0;

  bool get _derniere => _page == _etapes.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _terminer(String destination) async {
    HapticFeedback.selectionClick();
    await ref.read(onboardingVuProvider.notifier).terminer();
    if (mounted) context.go(destination);
  }

  void _suivant() {
    if (_derniere) {
      _terminer(AppRouter.connexionPath);
      return;
    }
    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    if (reduireAnimations) {
      _pages.jumpToPage(_page + 1);
    } else {
      _pages.nextPage(duration: const Duration(milliseconds: 420), curve: AppMotion.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête : marque à gauche, « Passer » à droite (masqué sur la
            // dernière page, où le bouton principal fait déjà terminer).
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
              child: Row(
                children: [
                  const TontineLogo(size: 32),
                  const SizedBox(width: AppSpacing.xs),
                  const Expanded(child: Text(AppConstants.appName, style: AppTypography.bodyStrong)),
                  AnimatedOpacity(
                    opacity: _derniere ? 0 : 1,
                    duration: AppMotion.fast,
                    child: IgnorePointer(
                      ignoring: _derniere,
                      child: TextButton(
                        onPressed: () => _terminer(AppRouter.connexionPath),
                        child: Text(context.l10n.onboardingSkip),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _etapes.length,
                onPageChanged: (page) {
                  HapticFeedback.selectionClick();
                  setState(() => _page = page);
                },
                itemBuilder: (context, index) => _PageEtape(
                  etape: _etapes[index],
                  index: index,
                  controleur: _pages,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Column(
                children: [
                  _Indicateur(nombre: _etapes.length, actif: _page),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: _derniere ? context.l10n.onboardingStart : context.l10n.commonNext,
                      icon: _derniere ? null : Icons.arrow_forward,
                      variant: AppButtonVariant.accent,
                      onPressed: _suivant,
                    ),
                  ),
                  // Emplacement réservé : le bouton principal ne saute pas
                  // quand l'action secondaire apparaît sur la dernière page.
                  SizedBox(
                    height: 48,
                    child: AnimatedOpacity(
                      opacity: _derniere ? 1 : 0,
                      duration: AppMotion.medium,
                      child: IgnorePointer(
                        ignoring: !_derniere,
                        child: TextButton(
                          onPressed: () => _terminer(AppRouter.rejoindrePath),
                          child: Text(context.l10n.onboardingHaveCode),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une page : illustration dans un panneau foncé, puis titre et texte. Au
/// glissement, l'illustration se déplace moins vite que la page et s'estompe
/// (parallaxe) : la profondeur rend le geste plus physique.
class _PageEtape extends StatelessWidget {
  const _PageEtape({required this.etape, required this.index, required this.controleur});

  final _Etape etape;
  final int index;
  final PageController controleur;

  @override
  Widget build(BuildContext context) {
    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedBuilder(
                animation: controleur,
                builder: (context, child) {
                  final page = controleur.hasClients && controleur.position.haveDimensions
                      ? controleur.page ?? controleur.initialPage.toDouble()
                      : 0.0;
                  final decalage = (index - page).clamp(-1.0, 1.0);
                  if (reduireAnimations) return child!;
                  return Opacity(
                    opacity: 1 - decalage.abs() * 0.5,
                    child: Transform.translate(offset: Offset(decalage * 90, 0), child: child),
                  );
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: FittedBox(fit: BoxFit.scaleDown, child: etape.illustration),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(etape.titre(context.l10n), style: AppTypography.pageTitle.copyWith(fontSize: 28, height: 34 / 28)),
          const SizedBox(height: AppSpacing.sm),
          Text(etape.texte(context.l10n), style: AppTypography.body.copyWith(color: AppColors.slate)),
        ],
      ),
    );
  }
}

/// Points de pagination : le point actif s'allonge en pilule.
class _Indicateur extends StatelessWidget {
  const _Indicateur({required this.nombre, required this.actif});

  final int nombre;
  final int actif;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.createStepOf(actif + 1, nombre),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < nombre; i++)
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == actif ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == actif ? AppColors.indigo : AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Le cercle des membres : le point ambre (celui qui reçoit la cagnotte)
/// fait le tour du cercle une fois, puis s'arrête — on comprend le principe
/// de la tontine sans lire.
class _IllustrationCercle extends StatelessWidget {
  const _IllustrationCercle();

  @override
  Widget build(BuildContext context) {
    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: reduireAnimations ? 4 : 0, end: 4),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, valeur, _) => TontineLogo(
            size: 200,
            activeIndex: valeur.round(),
            backgroundColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            context.l10n.onboardingCircleCaption,
            style: AppTypography.secondary.copyWith(color: AppColors.surface),
          ),
        ),
      ],
    );
  }
}

/// Une collecte en cours, avec les vrais composants de l'app.
class _IllustrationCollecte extends StatelessWidget {
  const _IllustrationCollecte();

  @override
  Widget build(BuildContext context) {
    return _MiniCarte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.onboardingCollectOverline, style: AppTypography.overline),
          const SizedBox(height: AppSpacing.xs),
          Text(formatAmount(37500), style: AppTypography.amountXl.copyWith(fontSize: 30)),
          Text(context.l10n.tourCollectedOf(formatAmount(50000)), style: AppTypography.secondary),
          const SizedBox(height: AppSpacing.md),
          const AppProgressBar(value: 0.75, color: AppColors.accent),
          const SizedBox(height: AppSpacing.md),
          _LigneMembre(nom: 'Aïcha Ndiaye', pastille: AppPill(label: context.l10n.statusPaid, tone: AppTone.success)),
          _LigneMembre(nom: 'Rose Domche', pastille: AppPill(label: context.l10n.statusPaid, tone: AppTone.success)),
          _LigneMembre(nom: 'Fatou Diallo', pastille: AppPill(label: context.l10n.statusLate, tone: AppTone.danger)),
        ],
      ),
    );
  }
}

/// Une déclaration de paiement qui passe de « En attente » à « Validée ».
class _IllustrationDeclaration extends StatelessWidget {
  const _IllustrationDeclaration();

  @override
  Widget build(BuildContext context) {
    final reduireAnimations = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduireAnimations ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, t, _) {
        final validee = t > 0.6;
        return _MiniCarte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const MemberAvatar(nomComplet: 'Fatou Diallo', size: 44),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fatou Diallo', style: AppTypography.bodyStrong),
                        Text(context.l10n.onboardingDeclaredPayment, style: AppTypography.secondary),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: AppMotion.medium,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                        child: child,
                      ),
                    ),
                    child: validee
                        ? AppPill(key: const ValueKey('validee'), label: context.l10n.declStatusApproved, tone: AppTone.success)
                        : AppPill(key: const ValueKey('attente'), label: context.l10n.declStatusPending, tone: AppTone.warning),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(formatAmount(12500), style: AppTypography.amountXl.copyWith(fontSize: 30)),
              const SizedBox(height: AppSpacing.sm),
              // La « preuve » : une capture de reçu Mobile Money stylisée.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: AppColors.indigo, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        context.l10n.onboardingMobileMoneyReceipt,
                        style: AppTypography.secondary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniCarte extends StatelessWidget {
  const _MiniCarte({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: child,
    );
  }
}

class _LigneMembre extends StatelessWidget {
  const _LigneMembre({required this.nom, required this.pastille});

  final String nom;
  final Widget pastille;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          MemberAvatar(nomComplet: nom, size: 32),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(nom, style: AppTypography.secondary.copyWith(color: AppColors.ink))),
          pastille,
        ],
      ),
    );
  }
}
