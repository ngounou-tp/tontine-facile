import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Petites informations de session conservées sur l'appareil :
/// le groupe affiché pour chaque compte, et un code d'invitation saisi à
/// l'inscription mais pas encore utilisable (email à confirmer d'abord).
abstract interface class PreferencesSession {
  String? groupeCourant(String uid);
  Future<void> choisirGroupe(String uid, String groupeId);

  /// Émet l'identifiant du compte dont le groupe courant vient de changer.
  Stream<String> get changementsGroupe;

  String? get codeInvitationEnAttente;
  Future<void> setCodeInvitationEnAttente(String? code);
}

class SharedPreferencesSession implements PreferencesSession {
  SharedPreferencesSession(this._preferences);

  final SharedPreferences? _preferences;
  final _changements = StreamController<String>.broadcast();
  final _memoire = <String, String>{};
  String? _codeMemoire;

  static String _cleGroupe(String uid) => 'groupe_courant.$uid';
  static const _cleCode = 'code_invitation_en_attente';

  @override
  String? groupeCourant(String uid) => _preferences?.getString(_cleGroupe(uid)) ?? _memoire[uid];

  @override
  Future<void> choisirGroupe(String uid, String groupeId) async {
    _memoire[uid] = groupeId;
    await _preferences?.setString(_cleGroupe(uid), groupeId);
    _changements.add(uid);
  }

  @override
  Stream<String> get changementsGroupe => _changements.stream;

  @override
  String? get codeInvitationEnAttente => _preferences?.getString(_cleCode) ?? _codeMemoire;

  @override
  Future<void> setCodeInvitationEnAttente(String? code) async {
    _codeMemoire = code;
    if (code == null) {
      await _preferences?.remove(_cleCode);
    } else {
      await _preferences?.setString(_cleCode, code);
    }
  }
}
