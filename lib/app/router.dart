import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/session.dart';
import '../domain/entities/tontine.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/pages/choix_parcours_page.dart';
import '../features/auth/presentation/pages/connexion_page.dart';
import '../features/auth/presentation/pages/inscription_page.dart';
import '../features/auth/presentation/pages/rejoindre_tontine_page.dart';
import '../features/auth/presentation/pages/verify_email_page.dart';
import '../features/cotisations/presentation/pages/declarations_en_attente_page.dart';
import '../features/cotisations/presentation/pages/detail_declaration_page.dart';
import '../features/cotisations/presentation/pages/saisir_cotisation_page.dart';
import '../features/echeancier/presentation/pages/echeancier_page.dart';
import '../features/espace_membre/presentation/pages/declarer_paiement_page.dart';
import '../features/espace_membre/presentation/pages/espace_membre_page.dart';
import '../features/membres/presentation/pages/ajouter_membre_page.dart';
import '../features/membres/presentation/pages/attribuer_nom_page.dart';
import '../features/membres/presentation/pages/fiche_membre_page.dart';
import '../features/membres/presentation/pages/membres_page.dart';
import '../features/onboarding/application/onboarding_provider.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/tontine/presentation/pages/creer_tontine_page.dart';
import '../features/tontine/presentation/pages/home_page.dart';
import '../features/tontine/presentation/pages/modifier_tontine_page.dart';
import '../features/tontine/presentation/pages/reglages_page.dart';
import '../shared/pages/route_placeholder_page.dart';
import 'firebase_setup.dart';

/// Fournit le routeur réactif à l'état Firebase et au profil Firestore.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRouter.rootPath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => AppRouter.redirect(ref, state),
    routes: AppRouter.routes,
  );
});

abstract final class AppRouter {
  static const rootPath = '/';
  static const onboardingPath = '/decouvrir';
  static const connexionPath = '/connexion';
  static const inscriptionPath = '/inscription';
  static const rejoindrePath = '/rejoindre';
  static const verifyEmailPath = '/verifier-email';
  static const choixPath = '/bienvenue';
  static const creerTontinePath = '/creer-tontine';
  static const accueilPath = '/accueil';
  static const espaceMembrePath = '/espace-membre';
  static const membresPath = '/membres';
  static const echeancierPath = '/echeancier';
  static const reglagesPath = '/reglages';
  static const cotisationsPath = '/cotisations';
  static const declarationsPath = '/declarations';

  static final routes = <RouteBase>[
    GoRoute(
      path: rootPath,
      builder: (_, _) => const RoutePlaceholderPage(title: 'TontineFacile'),
    ),
    GoRoute(
      path: onboardingPath,
      name: 'decouvrir',
      builder: (_, _) => const OnboardingPage(),
    ),
    GoRoute(
      path: connexionPath,
      name: 'connexion',
      builder: (_, _) => const ConnexionPage(),
    ),
    GoRoute(
      path: inscriptionPath,
      name: 'inscription',
      builder: (_, state) => InscriptionPage(codeInvitation: state.extra as String?),
    ),
    GoRoute(
      path: rejoindrePath,
      name: 'rejoindre',
      builder: (_, _) => const RejoindreTontinePage(),
    ),
    GoRoute(
      path: verifyEmailPath,
      name: 'verifier-email',
      builder: (_, _) => const VerifyEmailPage(),
    ),
    GoRoute(
      path: choixPath,
      name: 'bienvenue',
      builder: (_, _) => const ChoixParcoursPage(),
    ),
    GoRoute(
      path: creerTontinePath,
      name: 'creer-tontine',
      builder: (_, _) => const CreerTontinePage(),
    ),
    GoRoute(
      path: accueilPath,
      name: 'accueil',
      builder: (_, _) => const HomePage(),
    ),
    GoRoute(
      path: espaceMembrePath,
      name: 'espace-membre',
      builder: (_, _) => const EspaceMembrePage(),
    ),
    GoRoute(
      path: '$espaceMembrePath/declarer/:nomId',
      name: 'declarer-paiement',
      builder: (_, state) => DeclarerPaiementPage(nomId: state.pathParameters['nomId']!),
    ),
    GoRoute(
      path: membresPath,
      name: 'membres',
      builder: (_, _) => const MembresPage(),
    ),
    GoRoute(
      path: '$membresPath/ajouter',
      name: 'ajouter-membre',
      builder: (_, _) => const AjouterMembrePage(),
    ),
    GoRoute(
      path: '$membresPath/noms/nouveau',
      name: 'attribuer-nom',
      builder: (_, _) => const AttribuerNomPage(),
    ),
    GoRoute(
      path: '$membresPath/noms/:nomId',
      name: 'modifier-nom',
      builder: (_, state) => AttribuerNomPage(nomId: state.pathParameters['nomId']),
    ),
    GoRoute(
      path: '$membresPath/:membreId',
      name: 'fiche-membre',
      builder: (_, state) => FicheMembrePage(membreId: state.pathParameters['membreId']!),
    ),
    GoRoute(
      path: echeancierPath,
      name: 'echeancier',
      builder: (_, _) => const EcheancierPage(),
    ),
    GoRoute(
      path: reglagesPath,
      name: 'reglages',
      builder: (_, _) => const ReglagesPage(),
    ),
    GoRoute(
      path: '$reglagesPath/tontine',
      name: 'modifier-tontine',
      builder: (_, _) => const ModifierTontinePage(),
    ),
    GoRoute(
      path: '$cotisationsPath/:tourId',
      name: 'cotisations',
      builder: (_, state) => SaisirCotisationPage(tourId: state.pathParameters['tourId']!),
    ),
    GoRoute(
      path: declarationsPath,
      name: 'declarations',
      builder: (_, _) => const DeclarationsEnAttentePage(),
    ),
    GoRoute(
      path: '$declarationsPath/:declarationId',
      name: 'detail-declaration',
      builder: (_, state) =>
          DetailDeclarationPage(declarationId: state.pathParameters['declarationId']!),
    ),
  ];

  static String? redirect(Ref ref, GoRouterState state) {
    final location = state.uri.path;
    final sessionState = ref.read(sessionProvider);

    if (sessionState.isLoading) return null;
    if (sessionState.hasError) return connexionPath;

    final Session? session = sessionState.value;
    if (session == null) {
      // Premier lancement : la découverte de l'app passe avant tout le
      // reste. Une fois vue (ou passée), elle ne revient plus.
      final onboardingVu = ref.read(onboardingVuProvider);
      if (!onboardingVu) return location == onboardingPath ? null : onboardingPath;
      if (location == onboardingPath) return connexionPath;

      // /rejoindre reste accessible sans compte : on peut y prévisualiser une
      // tontine avant de créer un compte pour la rejoindre.
      return (_isPublic(location) || location == rejoindrePath)
          ? null
          : connexionPath;
    }

    // La vérification d'email n'est imposée qu'en environnement live : les
    // émulateurs locaux n'envoient pas de vrais emails, ce qui rendrait le
    // blocage impossible à lever en développement.
    if (FirebaseSetup.environment == FirebaseEnvironment.live &&
        !session.utilisateur.emailVerified) {
      return location == verifyEmailPath ? null : verifyEmailPath;
    }

    if (session.profil == null) {
      return _isNoProfileDestination(location) ? null : choixPath;
    }

    final tontineState = ref.read(currentTontineProvider);
    if (tontineState.isLoading) return null;
    if (tontineState.hasError || tontineState.value == null) {
      return rejoindrePath;
    }

    final Tontine tontine = tontineState.requireValue!;
    final isAdmin = tontine.adminUid == session.utilisateur.uid;
    if (isAdmin) {
      if (_isPublic(location) || _isNoProfileDestination(location) ||
          location == rootPath ||
          location == espaceMembrePath || location.startsWith('$espaceMembrePath/') ||
          location == verifyEmailPath) {
        return accueilPath;
      }
      return null;
    }

    // Membre : les mêmes sections que l'administratrice (Accueil, Membres,
    // Échéancier, Réglages, Déclarations) sont ouvertes, mais en lecture
    // seule — chaque écran masque ses propres actions via `isAdminProvider`.
    // Seules les routes de création/édition/traitement restent bloquées ici
    // en plus (défense en profondeur, cohérent avec les règles Firestore).
    if (_isPublic(location) || _isNoProfileDestination(location) ||
        location == rootPath || location == verifyEmailPath ||
        _isAdminOnlyWriteDestination(location)) {
      return espaceMembrePath;
    }
    return null;
  }

  static bool _isPublic(String location) =>
      location == connexionPath || location == inscriptionPath || location == onboardingPath;

  static bool _isNoProfileDestination(String location) =>
      location == rejoindrePath ||
      location == creerTontinePath ||
      location == choixPath;

  // `$reglagesPath/tontine` et `$cotisationsPath/` n'y figurent pas :
  // `ModifierTontinePage` et `SaisirCotisationPage` restent accessibles en
  // lecture seule à un membre (voir `isAdminProvider`) — la seconde lui
  // permet de voir qui a déjà contribué à un tour.
  static bool _isAdminOnlyWriteDestination(String location) =>
      location == '$membresPath/ajouter' || location.startsWith('$membresPath/noms/');
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<Session?>>(sessionProvider, (_, _) {
      notifyListeners();
    });
    ref.listen<AsyncValue<Tontine?>>(currentTontineProvider, (_, _) {
      notifyListeners();
    });
    ref.listen<bool>(onboardingVuProvider, (_, _) {
      notifyListeners();
    });
  }
}
