import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Cible d'exécution de Firebase.
///
/// - [live] : le projet Firebase en ligne (par défaut).
/// - [local] : les émulateurs Auth et Firestore lancés par
///   `firebase emulators:start --only auth,firestore`.
enum FirebaseEnvironment { live, local }

/// Initialise Firebase et, en mode [FirebaseEnvironment.local], branche les
/// émulateurs sur l'hôte joignable depuis le type d'appareil courant.
///
/// Choix de la cible au lancement :
///
/// ```powershell
/// flutter run                                   # live (défaut)
/// flutter run --dart-define=FIREBASE_ENV=local  # émulateurs
/// ```
///
/// Ou, de façon équivalente, via les fichiers `env/local.json` /
/// `env/live.json` (voir aussi `.vscode/launch.json`, qui expose les deux
/// comme configurations de lancement dans VS Code) :
///
/// ```powershell
/// flutter run --dart-define-from-file=env/local.json
/// flutter run --dart-define-from-file=env/live.json
/// ```
///
/// Pour un téléphone physique, l'IP LAN de la machine hôte doit être fournie :
///
/// ```powershell
/// flutter run --dart-define=FIREBASE_ENV=local --dart-define=EMULATOR_HOST=192.168.1.20
/// ```
class FirebaseSetup {
  const FirebaseSetup._();

  static const int _authPort = 9099;
  static const int _firestorePort = 8080;

  /// Cible demandée via `--dart-define=FIREBASE_ENV=local`. `live` par défaut.
  static FirebaseEnvironment get environment {
    const value = String.fromEnvironment('FIREBASE_ENV', defaultValue: 'live');
    return value == 'local'
        ? FirebaseEnvironment.local
        : FirebaseEnvironment.live;
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (environment == FirebaseEnvironment.local) {
      await _connectEmulators();
    }
  }

  static Future<void> _connectEmulators() async {
    final host = emulatorHost;

    await FirebaseAuth.instance.useAuthEmulator(host, _authPort);
    // L'émulateur Auth n'a pas besoin de la protection reCAPTCHA de
    // l'inscription/connexion par mot de passe (elle vérifie l'appareil
    // contre les vrais serveurs Google, indisponibles ou superflus en local
    // — sur un appareil physique sans accès internet réel, ou pour lequel
    // l'empreinte de signature du build debug n'est pas enregistrée côté
    // Firebase, cette vérification échoue ou reste bloquée indéfiniment).
    await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);

    // Sur un hot restart, Firestore est déjà démarré : l'appel relance une
    // exception qui peut être ignorée sans risque.
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(host, _firestorePort);
    } catch (error) {
      debugPrint('useFirestoreEmulator ignoré (déjà configuré) : $error');
    }

    debugPrint('Firebase : émulateurs actifs sur $host '
        '(auth:$_authPort, firestore:$_firestorePort)');
  }

  /// Adresse de la machine qui héberge les émulateurs, vue depuis l'appareil.
  ///
  /// - Web / desktop / simulateur iOS : `127.0.0.1`.
  /// - Émulateur Android : `10.0.2.2` (alias de la machine hôte).
  /// - Appareil physique : `--dart-define=EMULATOR_HOST=<IP LAN de l'hôte>`.
  static String get emulatorHost {
    const override = String.fromEnvironment('EMULATOR_HOST');
    if (override.isNotEmpty) return override;

    if (kIsWeb) return 'localhost';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return '127.0.0.1';
    }
  }
}
