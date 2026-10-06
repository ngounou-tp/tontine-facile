import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _firebaseAuth;

  /// Les appels réseau Firebase Auth (SDK natif) peuvent rester bloqués sans
  /// jamais résoudre ni rejeter leur `Future` — observé notamment quand la
  /// vérification reCAPTCHA de l'inscription par mot de passe ne peut pas
  /// joindre les serveurs Google (appareil sans accès internet réel,
  /// empreinte de build non enregistrée...). Sans ce délai, l'écran reste
  /// bloqué en chargement indéfiniment plutôt que d'afficher une erreur.
  static const _delaiReseau = Duration(seconds: 20);

  Future<T> _avecDelai<T>(Future<T> Function() action) {
    return action().timeout(
      _delaiReseau,
      onTimeout: () => throw const NetworkException('auth timeout'),
    );
  }

  // `GoogleSignIn.instance.initialize()` ne doit être appelé qu'une seule
  // fois : on met en cache le Future pour que les appels concurrents ou
  // répétés à [signInWithGoogle] attendent la même initialisation.
  Future<void>? _googleSignInInit;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= gsi.GoogleSignIn.instance.initialize();
  }

  @override
  AppUser? get currentUser => _toAppUser(_firebaseAuth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_toAppUser);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _avecDelai(
        () => _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
      return _requireAppUser(credential.user);
    } on fb.FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _avecDelai(
        () => _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
      return _requireAppUser(credential.user);
    } on fb.FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    gsi.GoogleSignInAccount compte;
    try {
      compte = await gsi.GoogleSignIn.instance.authenticate();
    } on gsi.GoogleSignInException catch (error) {
      if (error.code == gsi.GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw ExternalSignInException(error.description ?? error.code.name);
    }

    final idToken = compte.authentication.idToken;
    if (idToken == null) {
      throw const ExternalSignInException('google: missing idToken');
    }

    try {
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final resultat = await _firebaseAuth.signInWithCredential(credential);
      return _requireAppUser(resultat.user);
    } on fb.FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Ne déconnecte Google que si on l'a déjà initialisé (sinon inutile, et
    // l'appeler avant `initialize()` lèverait une erreur).
    if (_googleSignInInit != null) {
      await gsi.GoogleSignIn.instance.signOut();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
  }

  @override
  Future<AppUser?> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    try {
      await user.reload();
    } on fb.FirebaseAuthException catch (error) {
      throw mapFirebaseAuthException(error);
    }
    return _toAppUser(_firebaseAuth.currentUser);
  }

  AppUser _requireAppUser(fb.User? user) {
    final appUser = _toAppUser(user);
    if (appUser == null) {
      throw const UnknownAuthException('no user returned');
    }
    return appUser;
  }

  AppUser? _toAppUser(fb.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      emailVerified: user.emailVerified,
    );
  }
}

/// Traduit un code d'erreur Firebase Auth en `AuthException` du domaine.
///
/// Fonction pure et testable indépendamment de Firebase : construire un
/// `FirebaseAuthException` ne nécessite pas `Firebase.initializeApp`.
AuthException mapFirebaseAuthException(fb.FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return const InvalidCredentialsException();
    case 'email-already-in-use':
      return const EmailAlreadyInUseException();
    case 'weak-password':
      return const WeakPasswordException();
    case 'invalid-email':
      return const InvalidEmailException();
    case 'user-disabled':
      return const UserDisabledException();
    case 'too-many-requests':
      return const TooManyRequestsException();
    default:
      return UnknownAuthException(error.code);
  }
}
