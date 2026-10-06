# DjanguiBook

## Objectif
DjanguiBook (anciennement TontineFacile) est une application mobile Flutter destinée à faciliter la gestion d'une tontine (association
rotative d'épargne et de crédit très répandue en Afrique de l'Ouest et Centrale). Elle permet à une
administratrice de créer et paramétrer son groupe, d'inviter ses membres, de suivre l'échéancier des tours et
la collecte des cotisations, tandis que chaque membre peut suivre sa situation, déclarer ses paiements et
consulter le fonctionnement du groupe.

## Fonctionnalités principales
- **Authentification** : création de compte (email/mot de passe ou Google), connexion, réinitialisation du
  mot de passe, vérification d'email.
- **Deux parcours d'inscription** : l'administratrice crée sa tontine directement ; un membre invité rejoint
  via un code à 6 caractères transmis par l'administratrice.
- **Gestion de la tontine** : nom, montant par nom, nombre de noms, pénalités et délai de grâce, fréquence des
  échéances, mode de répartition des parts — modifiable tant que l'échéancier n'a pas démarré.
- **Gestion des membres** : invitation, activation/désactivation, attribution de noms (parts entières ou
  fractionnées) à un ou plusieurs membres.
- **Échéancier** : génération automatique des tours une fois tous les noms attribués, réorganisation par
  glisser-déposer (avec motif et historique des changements) tant qu'un tour n'a pas été remis.
- **Cotisations** : saisie par l'administratrice pour chaque tour, avec calcul automatique des pénalités de
  retard selon les règles définies.
- **Déclarations de paiement** : un membre déclare un paiement (montant, date, preuve photo obligatoire) ;
  l'administratrice valide ou refuse avec motif ; un membre peut soumettre une nouvelle déclaration après un
  refus ou un paiement partiel.
- **Tableau de bord administratrice** : statistiques (membres actifs, taux de collecte, paiements à temps/en
  retard), tour en cours, déclarations en attente, accès rapide aux membres.
- **Espace membre** : situation personnelle (noms détenus, montants dus/versés), historique des cotisations et
  déclarations, et accès en lecture seule aux mêmes écrans que l'administratrice (Accueil, Membres,
  Échéancier, Déclarations, Réglages) pour une transparence totale sur la vie du groupe.
- **Gestion des erreurs et des états** : messages d'erreur explicites, écrans de chargement/vide/erreur sur
  toutes les listes, messages flash de confirmation après chaque action.

## Technologies et packages utilisés
- **Flutter / Dart** (SDK ^3.12.2)
- **flutter_riverpod** — gestion d'état (Provider, StreamProvider, FutureProvider, AsyncNotifier)
- **go_router** — navigation déclarative avec gardes de route réactives (redirection selon la session et le
  rôle admin/membre)
- **Firebase** : `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` — authentification et
  base de données temps réel, avec règles de sécurité Firestore dédiées (`firestore.rules`)
- **image_picker** + **flutter_image_compress** — capture et compression des preuves de paiement
- **intl** — formatage des dates
- **flutter_launcher_icons** — génération de l'icône de l'application
- **flutter_test** — tests unitaires et de widgets

## Architecture
Le code applicatif (`lib/`) suit une architecture en couches par fonctionnalité :

```
lib/
  app/          # point d'entrée, thème, routeur et ses gardes
  core/         # erreurs applicatives partagées
  domain/       # entités, règles métier et services purs (aucune dépendance Flutter/Firebase)
  data/         # modèles Firestore, datasources, repositories (implémentent les interfaces du domaine)
  features/     # un dossier par fonctionnalité :
    auth/             # inscription, connexion, session
    tontine/          # création/réglages de la tontine, tableau de bord
    membres/           # gestion des membres et des parts
    echeancier/        # génération et réorganisation des tours
    cotisations/       # saisie des cotisations et traitement des déclarations
    espace_membre/     # espace personnel du membre
    # chaque dossier contient application/ (providers, controllers) et presentation/ (pages, widgets)
  shared/       # widgets et état partagés (scaffold, barre de navigation, messages flash)
```

## Installation
1. Installer les dépendances :
   ```
   flutter pub get
   ```
2. La configuration Firebase (`lib/firebase_options.dart`, `android/app/google-services.json`) est déjà
   présente dans le dépôt : aucune étape supplémentaire n'est nécessaire pour lancer l'application.
3. (Optionnel) Pour développer hors ligne avec les émulateurs Firebase :
   ```
   firebase emulators:start --only auth,firestore
   ```

## Lancement de l'application
- Avec les émulateurs Firebase locaux :
  ```
  flutter run --dart-define-from-file=env/local.json
  ```
- Avec le projet Firebase de production :
  ```
  flutter run --dart-define-from-file=env/live.json
  ```

## Build de l'APK
```
flutter build apk --release
```
L'APK généré se trouve dans `build/app/outputs/flutter-apk/app-release.apk`.

## Tests réalisés
```
flutter test
flutter analyze
```
Le projet compte 25 fichiers de test (121 tests) couvrant :
- les **règles et services métier** du domaine (calcul des cotisations et pénalités, validation des parts et
  des déclarations, traitement des déclarations) ;
- les **repositories et modèles** Firestore (sérialisation, conversion entité/modèle) ;
- les **contrôleurs** (inscription, authentification, création/modification de tontine, membres,
  échéancier, réorganisation) ;
- les **widgets et pages** clés (formulaires, tableau de bord, fiche membre, échéancier, page de connexion),
  y compris des tests de non-débordement à taille d'écran réelle ;
- le **routeur** et ses redirections réactives selon la session, le profil et le rôle admin/membre.

`flutter analyze` ne remonte aucune erreur (seulement quelques infos de style pré-existantes).



## Difficultés rencontrées
- **Réactivité de la session utilisateur** : la session applicative devait refléter non seulement les
  changements Firebase Auth, mais aussi l'apparition du profil Firestore juste après avoir rejoint une
  tontine (sans nouvel événement d'authentification) — résolu par un flux combiné qui re-souscrit au profil à
  chaque changement d'utilisateur.
- **Règle de sécurité Firestore avec champ absent** : la réclamation d'un membre invité échouait
  systématiquement à cause d'un accès direct à un champ (`uid`) absent du document plutôt que nul, un piège
  classique du langage des règles Firestore (résolu avec `resource.data.get('uid', null)`).
- **Course entre navigation et propagation d'état** : naviguer immédiatement après une écriture Firestore
  pouvait rediriger l'utilisateur vers le mauvais écran avant que l'état réactif (session, tontine courante)
  n'ait eu le temps de se mettre à jour — résolu en attendant explicitement la propagation avant de naviguer.
- **Cohabitation des rôles admin/membre sur les mêmes écrans** : ouvrir les écrans de l'administratrice aux
  membres en lecture seule sans dupliquer les pages a demandé un provider dédié (`isAdminProvider`) consulté
  par chaque écran pour masquer ses actions réservées.

## Auteur
Patricia Tchuinteu ([ngounou-tp](https://github.com/ngounou-tp))
