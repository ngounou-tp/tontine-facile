import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/l10n.dart';

/// État de chargement d'un écran : un squelette qui esquisse la mise en page
/// à venir (une grande carte, puis des lignes) plutôt qu'un spinner centré.
/// Le contenu semble arriver plus vite, et l'écran ne « saute » pas quand
/// les données s'affichent. [message] est lu par les lecteurs d'écran.
class LoadingView extends StatefulWidget {
  const LoadingView({this.message, super.key});

  final String? message;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulsation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respiration lente du squelette, coupée si le système demande de
    // réduire les animations.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulsation.stop();
      _pulsation.value = 1;
    } else if (!_pulsation.isAnimating) {
      _pulsation.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulsation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.message ?? context.l10n.commonLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.45, end: 1).animate(
            CurvedAnimation(parent: _pulsation, curve: Curves.easeInOut),
          ),
          child: const SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bloc(largeur: 180, hauteur: 28),
                SizedBox(height: AppSpacing.xs),
                _Bloc(largeur: 240, hauteur: 16),
                SizedBox(height: AppSpacing.lg),
                _Bloc(hauteur: 168, rayon: AppSpacing.cardRadius),
                SizedBox(height: AppSpacing.lg),
                _Ligne(),
                SizedBox(height: AppSpacing.sm),
                _Ligne(),
                SizedBox(height: AppSpacing.sm),
                _Ligne(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Row(
        children: [
          _Bloc(largeur: 40, hauteur: 40, rayon: 20),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bloc(largeur: 140, hauteur: 14),
                SizedBox(height: AppSpacing.xs),
                _Bloc(largeur: 96, hauteur: 12),
              ],
            ),
          ),
          _Bloc(largeur: 64, hauteur: 14),
        ],
      ),
    );
  }
}

class _Bloc extends StatelessWidget {
  const _Bloc({this.largeur, required this.hauteur, this.rayon = 6});

  final double? largeur;
  final double hauteur;
  final double rayon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largeur ?? double.infinity,
      height: hauteur,
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(rayon),
      ),
    );
  }
}
