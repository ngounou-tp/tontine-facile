# DjanguiBook

## Objectif
DjanguiBook (anciennement TontineFacile) est une application mobile Flutter destinée à faciliter la gestion d'une tontine (association
rotative d'épargne et de crédit très répandue en Afrique de l'Ouest et Centrale). Elle permet à une
administratrice de créer et paramétrer son groupe, d'inviter ses membres, de suivre l'échéancier des tours et
la collecte des cotisations, tandis que chaque membre peut suivre sa situation, déclarer ses paiements et
consulter le fonctionnement du groupe.

## Fonctionnalités principales
- **Authentification** : création de compte (email/mot de passe, Google, Apple), connexion,
  réinitialisation du mot de passe, confirmation d'email.
- **Plusieurs groupes par compte** : rôles propres à chaque groupe, page « Mes groupes » pour passer de l'un
  à l'autre, en créer ou en rejoindre.
- **Français et anglais** : toute l'interface, les montants et les dates suivent la langue choisie.
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
- **Supabase** (`supabase_flutter`) — authentification, base Postgres avec RLS, fonctions SQL, temps réel et
  stockage privé des preuves ; `google_sign_in` et `sign_in_with_apple` pour les connexions externes
- **flutter_localizations / gen-l10n** — interface bilingue (fichiers `lib/l10n/app_fr.arb`, `app_en.arb`)
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
  data/         # repositories Supabase (implémentent les interfaces), conversions, services d'auth
  l10n/         # textes FR/EN et libellés traduits des notions du domaine
  features/     # un dossier par fonctionnalité :
    auth/             # inscription, connexion, session
    tontine/          # création/réglages de la tontine, tableau de bord
    membres/           # gestion des membres et des parts
    echeancier/        # génération et réorganisation des tours
    cotisations/       # saisie des cotisations et traitement des déclarations
    espace_membre/     # espace personnel du membre
    groupes/           # groupes multiples : liste, choix du groupe affiché
    # chaque dossier contient application/ (providers, controllers) et presentation/ (pages, widgets)
  shared/       # widgets et état partagés (scaffold, barre de navigation, messages flash)
```

## Installation
1. Installer les dépendances : `flutter pub get`
2. Créer un projet sur [supabase.com](https://supabase.com) (offre gratuite), puis appliquer le schéma :
   ```
   supabase link --project-ref <ref-du-projet>
   supabase db push
   ```
3. Dans le tableau de bord Supabase :
   - **Authentication → URL Configuration** : ajouter `djanguibook://login-callback` aux URL de redirection ;
   - **Authentication → Providers** : activer Google (ID client « Web ») et Apple si besoin ;
   - **Authentication → SMTP** : brancher un SMTP externe gratuit (ex. Brevo) — l'envoi intégré est limité
     à quelques emails par heure.
4. Copier `env/live.json.example` en `env/live.json` (ignoré par git) et y mettre l'URL du projet et sa clé
   publique (`anon` / « publishable »). Cette clé n'ouvre rien d'elle-même : toutes les tables sont protégées
   par la RLS.

### E-mails d'invitation
Quand le bureau ajoute un membre avec une adresse e-mail, l'Edge Function `send-invitation-email` lui envoie
son code et la marche à suivre (en français ou en anglais, selon la langue de la personne qui invite). Le
résultat est suivi dans `invitation_deliveries`, lisible par le bureau seul.
1. Déployer la fonction : `supabase functions deploy send-invitation-email`
2. Secrets : `supabase secrets set INVITATION_WEBHOOK_SECRET=<aléatoire> SMTP_HOST=smtp-relay.brevo.com
   SMTP_PORT=587 SMTP_USER=<...> SMTP_PASS=<...> MAIL_EXPEDITEUR="DjanguiBook <no-reply@...>"`
   (et `LIEN_APPLICATION` une fois l'app publiée).
3. **Database → Webhooks** : sur `group_invitations`, événement `INSERT`, appeler la fonction
   `send-invitation-email` avec l'en-tête `x-webhook-secret: <le même secret>`.

Sans SMTP configuré, l'envoi est consigné en échec avec un message invitant à partager le code autrement.

## Lancement de l'application
- Projet Supabase en ligne : `flutter run --dart-define-from-file=env/live.json`
- Supabase local (Docker) : `supabase start`, reporter la clé affichée dans `env/local.json`, puis
  `flutter run --dart-define-from-file=env/local.json`

L'application est disponible en **français et en anglais** (langue du téléphone par défaut, choix dans
Réglages). Un même compte peut appartenir à **plusieurs groupes**, avec des rôles différents dans chacun
(propriétaire, président, trésorier, commissaire aux comptes, membre).

## Build
- Android (AAB pour le Play Store) : renseigner `android/key.properties` (modèle :
  `android/key.properties.example`), puis `flutter build appbundle --release --dart-define-from-file=env/live.json`
- iOS : `flutter build ipa --release --dart-define-from-file=env/live.json` (Xcode 26 requis)

## Tests
```
flutter analyze
flutter test                          # domaine, contrôleurs, écrans, routeur
supabase/tests/run_local.sh           # base de données : RLS et fonctions SQL (pgTAP), sans Docker
supabase/tests/run_api_local.sh       # repositories Dart et Edge Functions contre une vraie API PostgREST
(cd supabase/functions && deno test tests/*.ts)   # e-mails d'invitation (Deno)
```
- **Domaine** : calculs de cotisations et pénalités, parts, échéancier, réorganisation, déclarations.
- **Base de données** : chaque règle d'accès (isolation entre groupes, rôles, usurpation impossible,
  invitations, validations atomiques) a son test pgTAP.
- **Intégration** : création, invitation, adhésion, échéancier, déclaration et validation de bout en bout,
  avec trois comptes réels contre l'API.
- **Interface** : formulaires, tableau de bord, fiche membre, échéancier, groupes, routeur et redirections
  selon la session, les groupes et les rôles ; textes vérifiés en français et en anglais.

Le plan de route complet (monétisation, notifications, publication, module Caisse) est dans
[`ROADMAP.md`](ROADMAP.md).

## Difficultés rencontrées (version Firebase d'origine)
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
