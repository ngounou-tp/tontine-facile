import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF16255A);
  static const slate = Color(0xFF4A4F5C);
  static const canvas = Color(0xFFEEF0F6);
  static const surface = Color(0xFFFFFFFF);
  static const indigo = Color(0xFF2F4590);
  static const success = Color(0xFF2F7D5D);
  static const warning = Color(0xFFC98A16);
  static const accent = Color(0xFFE2A03F);
  static const danger = Color(0xFFB5432F);
  static const line = Color(0xFFD3D8E4);

  /// Texte posé sur un fond teinté `warning` : l'ambre de [warning] seul
  /// tombe sous 3:1 de contraste en 12 px, illisible au soleil.
  static const warningInk = Color(0xFF8A5A00);

  /// Texte secondaire sur les cartes foncées ([ink]) : blanc à 72 %, assez
  /// lisible sans concurrencer le chiffre principal.
  static const onInkMuted = Color(0xB8FFFFFF);

  /// Teintes des avatars à initiales : sourdes et assez foncées pour que les
  /// initiales restent lisibles sur leur propre fond teinté à 14 %.
  static const avatarPalette = [
    indigo,
    success,
    warningInk,
    danger,
    Color(0xFF6B3FA0),
    Color(0xFF1F6F8B),
  ];
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const cardRadius = 16.0;
  static const controlRadius = 12.0;
}

/// Courbes et durées de toutes les animations de l'app. Une animation d'UI
/// reste sous 300 ms : au-delà, l'interface paraît lente. Jamais de
/// `Curves.easeIn` sur une entrée : il démarre lentement, pile au moment où
/// l'œil regarde.
abstract final class AppMotion {
  /// Sortie franche pour l'UI : réagit tout de suite, se pose en douceur.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Déplacement d'un élément déjà à l'écran.
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// Retour au repos après un appui (bouton, carte).
  static const press = Duration(milliseconds: 120);

  /// Apparition/disparition d'un petit élément (pastille, compteur).
  static const fast = Duration(milliseconds: 180);

  /// Changement de contenu d'une carte ou d'une section.
  static const medium = Duration(milliseconds: 260);

  /// Remplissage d'une jauge : plus long, car il raconte une progression.
  static const progress = Duration(milliseconds: 700);

  /// Échelle d'un élément pressé : assez pour être senti, pas pour être vu.
  static const pressedScale = 0.97;
}

abstract final class AppTypography {
  /// Chiffres à chasse fixe : les montants ne « dansent » pas quand ils
  /// changent et s'alignent en colonne dans les listes.
  static const _tabular = [FontFeature.tabularFigures()];

  /// H1 (32px Sora Bold) : titres principaux, notamment le nom de l'app sur
  /// les écrans d'authentification.
  static const pageTitle = TextStyle(fontFamily: 'Sora', fontSize: 32, fontWeight: FontWeight.w600, height: 40 / 32, letterSpacing: -0.6, color: AppColors.ink);
  static const amountXl = TextStyle(fontFamily: 'Sora', fontSize: 34, fontWeight: FontWeight.w600, height: 40 / 34, letterSpacing: -0.8, color: AppColors.ink, fontFeatures: _tabular);
  static const screenTitle = TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24, letterSpacing: -0.4, color: AppColors.ink);

  /// Titre de section à l'intérieur d'un écran (« Tour en cours »,
  /// « Membres actifs ») : plus discret que [screenTitle], qui reste réservé
  /// au titre principal.
  static const sectionTitle = TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18, letterSpacing: -0.2, color: AppColors.ink);
  static const amount = TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w500, height: 28 / 20, color: AppColors.ink, fontFeatures: _tabular);

  /// Montant dans une ligne de liste : même corps que [body], chiffres
  /// tabulaires et graisse marquée pour se lire en premier.
  static const amountInline = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, height: 24 / 16, color: AppColors.ink, fontFeatures: _tabular);
  static const body = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: AppColors.ink);
  static const bodyStrong = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, height: 24 / 16, color: AppColors.ink);
  static const secondary = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: AppColors.slate);
  static const micro = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12, color: AppColors.slate);

  /// Sur-titre en capitales (« TOUR 3 · EN COURS ») : l'espacement élargi
  /// compense la lecture plus difficile des capitales.
  static const overline = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12, letterSpacing: 0.8, color: AppColors.slate);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.indigo,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ).copyWith(
        primary: AppColors.indigo,
        onPrimary: AppColors.surface,
        secondary: AppColors.accent,
        onSurface: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.indigo,
        foregroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.surface),
        actionsIconTheme: IconThemeData(color: AppColors.surface),
        titleTextStyle: TextStyle(
          color: AppColors.surface,
          fontFamily: 'Sora',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Chaque TabBar de l'app est logée dans l'AppBar (son paramètre
      // `bottom`) : sans ce thème, les libellés/indicateur reprennent les
      // couleurs par défaut prévues pour un fond clair et deviennent
      // quasi invisibles sur le nouveau fond bleu indigo.
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.surface,
        unselectedLabelColor: Color(0xB3FFFFFF),
        indicatorColor: AppColors.accent,
        labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400),
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Inter').copyWith(
        headlineMedium: const TextStyle(color: AppColors.ink, fontFamily: 'Sora', fontSize: 28, fontWeight: FontWeight.w600, height: 1.1),
        titleLarge: const TextStyle(color: AppColors.ink, fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: AppColors.ink, fontSize: 16, height: 1.4),
        bodyMedium: const TextStyle(color: AppColors.slate, fontSize: 14, height: 1.35),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: AppColors.canvas,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius), side: const BorderSide(color: AppColors.line)),
      ),
      // Toasts flottants, au-dessus de la barre de navigation : un SnackBar
      // collé au bord masque les onglets et paraît « système ».
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.surface),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius)),
        insetPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.lg))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.lg)),
        titleTextStyle: AppTypography.sectionTitle,
        contentTextStyle: AppTypography.secondary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.indigo,
        linearTrackColor: AppColors.canvas,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      // Transition « iOS » sur iOS, transition Android moderne (glissement +
      // fondu, comme les apps Google récentes) ailleurs : la page arrive d'où
      // l'œil l'attend, au lieu d'un zoom générique.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.controlRadius), borderSide: const BorderSide(color: AppColors.indigo, width: 2)),
        hintStyle: const TextStyle(color: AppColors.slate, fontFamily: 'Inter', fontSize: 15),
      ),
    );
  }
}