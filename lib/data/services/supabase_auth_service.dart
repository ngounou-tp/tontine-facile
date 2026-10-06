import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../supabase/supabase_config.dart';
import 'auth_service.dart';

/// [AuthService] sur Supabase Auth (email + mot de passe, Google, Apple).
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._auth, {this._googleServerClientId});

  final sb.GoTrueClient _auth;
  final String? _googleServerClientId;

  static const _delaiReseau = Duration(seconds: 20);

  Future<T> _avecDelai<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(
        _delaiReseau,
        onTimeout: () => throw const NetworkException('auth timeout'),
      );
    } on sb.AuthException catch (error) {
      throw mapSupabaseAuthException(error);
    } on SocketException catch (error) {
      throw NetworkException(error.message);
    }
  }

  Future<void>? _googleSignInInit;

  Future<void> _initialiserGoogle() => _googleSignInInit ??=
      gsi.GoogleSignIn.instance.initialize(serverClientId: _googleServerClientId);

  @override
  AppUser? get currentUser => toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.onAuthStateChange.map((etat) => toAppUser(etat.session?.user)).distinct(
            (a, b) => a?.uid == b?.uid && a?.emailVerified == b?.emailVerified,
          );

  @override
  Future<ResultatInscription> signUp({required String email, required String password}) =>
      _avecDelai(() async {
        final reponse = await _auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: SupabaseConfig.redirectUrl,
        );
        final utilisateur = toAppUser(reponse.user);
        if (utilisateur == null) throw const UnknownAuthException('no user returned');
        return (utilisateur: utilisateur, connecte: reponse.session != null);
      });

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _avecDelai(() async {
        final reponse = await _auth.signInWithPassword(email: email, password: password);
        final utilisateur = toAppUser(reponse.user);
        if (utilisateur == null) throw const UnknownAuthException('no user returned');
        return utilisateur;
      });

  @override
  Future<AppUser?> signInWithGoogle() async {
    await _initialiserGoogle();
    final gsi.GoogleSignInAccount compte;
    try {
      compte = await gsi.GoogleSignIn.instance.authenticate();
    } on gsi.GoogleSignInException catch (error) {
      if (error.code == gsi.GoogleSignInExceptionCode.canceled) return null;
      throw ExternalSignInException(error.description ?? error.code.name);
    }
    final idToken = compte.authentication.idToken;
    if (idToken == null) throw const ExternalSignInException('google: missing idToken');

    return _avecDelai(() async {
      final reponse = await _auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
      );
      return toAppUser(reponse.user);
    });
  }

  @override
  Future<AppUser?> signInWithApple() async {
    // Le nonce brut part vers Supabase, son empreinte vers Apple : Supabase
    // vérifie que le jeton a bien été émis pour cette demande.
    final nonceBrut = _nonce();
    final AuthorizationCredentialAppleID identifiants;
    try {
      identifiants = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(nonceBrut)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      throw ExternalSignInException(error.message);
    }
    final idToken = identifiants.identityToken;
    if (idToken == null) throw const ExternalSignInException('apple: missing identityToken');

    return _avecDelai(() async {
      final reponse = await _auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
        nonce: nonceBrut,
      );
      return toAppUser(reponse.user);
    });
  }

  String _nonce() {
    final aleatoire = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => aleatoire.nextInt(256)));
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInInit != null) await gsi.GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) => _avecDelai(
        () => _auth.resetPasswordForEmail(email, redirectTo: SupabaseConfig.redirectUrl),
      );

  @override
  Future<void> resendConfirmation(String email) => _avecDelai(
        () => _auth.resend(
          type: sb.OtpType.signup,
          email: email,
          emailRedirectTo: SupabaseConfig.redirectUrl,
        ),
      );

  @override
  Future<AppUser?> reloadUser() async {
    if (_auth.currentSession == null) return null;
    return _avecDelai(() async {
      final reponse = await _auth.getUser();
      return toAppUser(reponse.user);
    });
  }
}

AppUser? toAppUser(sb.User? user) {
  if (user == null) return null;
  return AppUser(
    uid: user.id,
    email: user.email,
    emailVerified: user.emailConfirmedAt != null,
  );
}

/// Traduit une erreur Supabase Auth en `AuthException` du domaine. Les
/// identifiants inconnus et les mots de passe faux donnent la même erreur :
/// les distinguer révélerait quels emails sont inscrits.
AuthException mapSupabaseAuthException(sb.AuthException error) {
  return switch (error.code) {
    'invalid_credentials' || 'user_not_found' => const InvalidCredentialsException(),
    'user_already_exists' || 'email_exists' => const EmailAlreadyInUseException(),
    'weak_password' => const WeakPasswordException(),
    'email_address_invalid' || 'validation_failed' => const InvalidEmailException(),
    'user_banned' => const UserDisabledException(),
    'email_not_confirmed' => const EmailNonConfirmeException(),
    'over_request_rate_limit' || 'over_email_send_rate_limit' => const TooManyRequestsException(),
    _ when error.statusCode == '429' => const TooManyRequestsException(),
    _ => UnknownAuthException(error.code ?? error.statusCode),
  };
}
