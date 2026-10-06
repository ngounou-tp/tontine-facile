import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/core/errors/app_exception.dart';
import 'package:tontinefacile/data/services/firebase_auth_service.dart';

void main() {
  group('mapFirebaseAuthException', () {
    test('regroupe wrong-password, user-not-found et invalid-credential',
        () {
      for (final code in [
        'wrong-password',
        'user-not-found',
        'invalid-credential',
      ]) {
        final result = mapFirebaseAuthException(
          FirebaseAuthException(code: code),
        );
        expect(result, isA<InvalidCredentialsException>());
      }
    });

    test('email-already-in-use', () {
      final result = mapFirebaseAuthException(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(result, isA<EmailAlreadyInUseException>());
    });

    test('weak-password', () {
      final result = mapFirebaseAuthException(
        FirebaseAuthException(code: 'weak-password'),
      );
      expect(result, isA<WeakPasswordException>());
    });

    test('invalid-email', () {
      final result = mapFirebaseAuthException(
        FirebaseAuthException(code: 'invalid-email'),
      );
      expect(result, isA<InvalidEmailException>());
    });

    test('user-disabled', () {
      final result = mapFirebaseAuthException(
        FirebaseAuthException(code: 'user-disabled'),
      );
      expect(result, isA<UserDisabledException>());
    });

    test('too-many-requests', () {
      final result = mapFirebaseAuthException(
        FirebaseAuthException(code: 'too-many-requests'),
      );
      expect(result, isA<TooManyRequestsException>());
    });

    test('code inconnu -> UnknownAuthException, message traduit, code conservé',
        () {
      final result = mapFirebaseAuthException(
        FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Ce mode de connexion est désactivé.',
        ),
      );
      expect(result, isA<UnknownAuthException>());
      expect(result.message, "Erreur d'authentification. Réessayez.");
      expect(result.details, 'operation-not-allowed');
    });

    test('code inconnu sans message -> code conservé dans details', () {
      final result = mapFirebaseAuthException(
        FirebaseAuthException(code: 'some-new-code'),
      );
      expect(result, isA<UnknownAuthException>());
      expect(result.details, 'some-new-code');
    });
  });
}
