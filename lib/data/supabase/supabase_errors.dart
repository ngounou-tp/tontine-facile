import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';

/// Traduit une erreur Supabase en [AppException] présentable.
///
/// Les fonctions SQL signalent leurs refus par un message stable
/// (`invitation_not_found`, `forbidden`...) : c'est lui qui est interprété,
/// jamais le texte libre d'une erreur Postgres.
Object mapSupabaseError(Object error) {
  if (error is AppException) return error;
  if (error is SocketException || error is TimeoutException || error is HttpException) {
    return NetworkException(error.toString());
  }
  if (error is PostgrestException) {
    return switch (error.message) {
      'invitation_not_found' => const InvitationIntrouvableException(),
      'invitation_already_used' => const InvitationDejaUtiliseeException(),
      'already_member' => const DejaMembreException(),
      'sign_in_required' => const SignInRequiredException(),
      'forbidden' => const ActionNonAutoriseeException(),
      'names_quota_exceeded' => const NamesQuotaExceededException(),
      'transfer_ownership_required' => const TransfertProprieteRequisException(),
      final code
          when const {
            'shares_required',
            'shares_must_total_one',
            'contact_required',
            'reason_required',
            'changes_required',
            'amount_exceeds_due',
            'declaration_not_pending',
            'turn_already_paid',
            'last_owner',
            'roles_required',
          }.contains(code) =>
        DonneesInvalidesException(code),
      _ when error.code == '42501' => ActionNonAutoriseeException(error.message),
      _ => DonneesInvalidesException(error.code ?? error.message),
    };
  }
  if (error is StorageException) {
    return error.statusCode == '403'
        ? ActionNonAutoriseeException(error.message)
        : DonneesInvalidesException(error.message);
  }
  return error;
}

/// Exécute [action] en convertissant ses erreurs avec [mapSupabaseError].
Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(mapSupabaseError(error), stackTrace);
  }
}
