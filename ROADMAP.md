# DjanguiBook — Roadmap (audit, architecture cible, lancement)

> Document de travail, 6 octobre 2026. Remplace le nom « TontineFacile ».
> Sources : audit complet du dépôt (branche `claude/intelligent-ride-whklnn`), cahier des charges
> « Caisse de réunion » (23 p.), recherches sur les offres gratuites et les règles des stores.

## État d'avancement (6 octobre 2026)

| Lot | État | Détail |
|---|---|---|
| 0 — Fondations | ✅ Fait | Nom DjanguiBook, FR/EN complet (420+ textes, choix dans Réglages), correctifs stores (signature Android, permissions iOS, iOS 15, portrait), hook de session, CI |
| 1 — Migration Supabase | ✅ Fait | Schéma + RLS + fonctions SQL (82 tests pgTAP), repositories Supabase (tests d'intégration contre PostgREST), auth email/Google/Apple, confirmation d'email et réinitialisation par lien profond, groupes multiples et rôles, faille d'usurpation fermée |
| 2 — Plateforme | 🟡 Commencé | ✅ Suppression de compte (anonymisation, groupes solitaires supprimés, propriétaire unique protégé). Reste : notifications push (FCM), rappels pg_cron, révocation du jeton Apple à la suppression (Edge Function, clés Apple requises), page web de suppression pour Play, profil, mise à jour forcée, Crashlytics |
| 3 — Monétisation | ⏳ À faire | RevenueCat, `feature_gates`, AdMob + UMP/ATT, console propriétaire |
| 4–5 — Module Caisse | ⏳ À faire | Règles §10 à valider par un bureau pilote |
| 6 — Publication | ⏳ À faire | Comptes stores, identifiants définitifs (`com.djanguibook.app` à confirmer), fiches, tests fermés |

**Pour lancer l'app aujourd'hui** : créer le projet Supabase et suivre la section Installation du README.

## 0. Décisions prises

| Sujet | Décision |
|---|---|
| Backend | **Migration complète vers Supabase** (plan gratuit). Firebase conservé uniquement pour l'envoi des push (FCM, gratuit sur le plan Spark). |
| Nom | **DjanguiBook** (identique en français et en anglais). ⚠️ Une app « Djangui » existe déjà au Cameroun : vérifier la disponibilité de la marque avant le dépôt. |
| Langues | Français + anglais dès la V1. Langue du téléphone par défaut, repli sur le français, choix manuel dans Réglages. |
| Multi-groupes | Un utilisateur peut appartenir à plusieurs groupes (tontines et caisses) et en administrer plusieurs, avec un rôle différent dans chacun. |
| Monétisation | Abonnement Premium via la facturation des stores (RevenueCat) **et** publicités (AdMob). Fonctions payantes, limites et emplacements publicitaires pilotés **à distance par la propriétaire de l'app**, sans mise à jour de l'app. |
| Comptes stores | Aucun pour l'instant : à créer (voir §8). |

## 1. Audit — constats

### Critiques (à corriger avant toute mise en production)
1. **Usurpation d'identité possible.** `utilisateurs/{uid}` est modifiable librement par son propriétaire
   (`firestore.rules`). Or `isMember()` et la règle de création des déclarations font confiance à
   `profile().tontineId` / `profile().membreId`. Un membre peut donc lire n'importe quelle tontine dont il
   connaît l'id et déclarer des paiements au nom d'un autre membre. Résolu par la migration (§2) : les
   appartenances sont écrites uniquement par le serveur et vérifiées par RLS.
2. **Release Android signée avec la clé debug** (`android/app/build.gradle.kts`) : refus par le Play Store.
3. **Identifiants `com.example.tontinefacile`** (Android et iOS) : refus par les deux stores.
4. **iOS : aucune description d'usage** (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) dans
   `Info.plist`. `image_picker` plante sur iPhone, et c'est un rejet App Review garanti.
5. **iOS : Google Sign-In sans URL scheme** (`REVERSED_CLIENT_ID`) et **sans Sign in with Apple**
   (guideline 4.8).
6. **Pas de suppression de compte dans l'app** : obligatoire sur les deux stores.

### Importants
- Modèle « 1 utilisateur = 1 tontine » (`Profil.tontineId`) et rôle unique (`tontine.adminUid`) :
  incompatibles avec le multi-groupes et les 4 rôles de la caisse.
- Aucune logique serveur : pas de notifications envoyées, pas de rappels, pas de calculs garantis.
- Preuves stockées en base64 dans des documents Firestore (limite de 1 Mo, coût de lecture élevé).
- Environ 720 chaînes en dur en français, sans ARB ni `gen-l10n`.
- Nom affiché incohérent : `tontinefacile` (Android), `Tontinefacile` (iOS), `TontineFacile` (app),
  et `"A new Flutter project."` comme description web.
- Pas de crash reporting, pas d'analytics, pas de mise à jour forcée, pas de politique de confidentialité ni
  de CGU, pas de liens d'invitation (Firebase Dynamic Links est arrêté depuis août 2025).
- Orientation paysage activée sur iPhone alors que l'UI est conçue pour le portrait.

### Points solides à conserver
- Couche `domain/` pure (règles, services, calculateurs) bien testée (environ 125 tests).
- Repositories derrière des interfaces : la migration remplace `data/` sans toucher `domain/` ni les écrans.
- Thème centralisé (`AppColors`, `AppSpacing`, `AppTypography`, `AppMotion`).
- Harnais de tests des règles de sécurité (`firestore-tests/`) : à porter en tests RLS (pgTAP).

## 2. Architecture cible (Supabase, plan gratuit)

```
Flutter app ──supabase_flutter──► Supabase
  │                                ├─ Auth : email + mot de passe, Google, Apple (id_token natif)
  │                                ├─ Postgres + RLS : toutes les données, isolées par groupe
  │                                ├─ Fonctions RPC Postgres (SECURITY DEFINER) : toute opération
  │                                │    financière, en transaction (verrous SELECT … FOR UPDATE)
  │                                ├─ pg_cron : retards, pénalités, rappels J-30/J-7/J-3/J-1
  │                                ├─ Storage privé : preuves, logos, PV (URLs signées)
  │                                └─ Edge Functions : envoi FCM, webhook RevenueCat, emails
  ├─ FCM (projet Firebase Spark)   ← push Android/iOS, gratuit
  ├─ RevenueCat SDK                ← abonnements stores
  └─ AdMob SDK + UMP               ← publicités et consentement
```

**Pourquoi des RPC Postgres plutôt que des Edge Functions pour l'argent :** l'atomicité est réelle
(transaction et verrou de ligne, ce qui satisfait ENF-12), elles ne consomment pas le quota de 500 000
invocations, et le type `numeric` élimine le risque d'arrondi des grands produits (montant × jours).
Le moteur de calcul est testé avec **pgTAP** (`supabase test db`, gratuit). Le jeu de référence §7.5
fait partie des tests obligatoires.

### Schéma (extrait)
```
profiles(id = auth.uid, display_name, phone, locale, created_at)
groups(id, kind['tontine'|'caisse'], name, logo_path, currency, timezone, created_by)
group_members(id, group_id, user_id NULL, display_name, phone, roles text[], status)
group_invitations(code, group_id, member_id, expires_at)        -- réclamation via RPC uniquement
-- Tontine rotative (portage du modèle actuel)
tontine_settings, noms, parts, tours, cotisations, declarations, proofs, changements
-- Caisse (cahier des charges §9)
cycles, cycle_rules(version), deposits, withdrawals, loans, loan_periods, payments,
penalties, approvals, ledger_entries (insert-only), cassations, distributions, audit_logs
-- Plateforme
device_tokens(user_id, token, platform), notifications(user_id, type, payload, read_at)
feature_gates, plans, entitlements_cache, ad_placements, app_config(min_version, …)
idempotency_keys(key, result, created_at)
```
- RLS : `is_member(group_id)` et `has_role(group_id, role)` sont des fonctions SQL stables qui lisent
  `group_members`. Aucune écriture directe sur les tables financières : on passe uniquement par les RPC.
- `ledger_entries` et `audit_logs` : `REVOKE UPDATE, DELETE`, et un trigger qui refuse toute modification.
- Les dates métier sont stockées en `date`, dans le fuseau horaire du groupe.

### Contraintes du plan gratuit et parades
| Limite | Parade |
|---|---|
| Projet mis en pause après 7 jours sans requête, ce qui arrête aussi pg_cron | Ping quotidien par GitHub Actions (gratuit). Un job de rattrapage idempotent recalcule les retards depuis la dernière exécution. |
| Pas de sauvegarde automatique | GitHub Action nocturne `pg_dump` chiffré vers Backblaze B2 (10 Go gratuits), avec un test de restauration trimestriel. |
| 500 Mo de base, 1 Go de fichiers | Preuves compressées (environ 100 Ko) et purgées 24 mois après la clôture. Alerte à 70 %. Passage en Pro (25 $/mois) quand les revenus le permettent. |
| SMTP intégré limité à quelques emails par heure | SMTP externe gratuit : Brevo (300 emails/jour). |
| Realtime : 200 connexions simultanées | Realtime uniquement sur les écrans ouverts (validations, séance). Ailleurs, rafraîchissement manuel. |
| Pas de cache hors ligne comme Firestore | Cache local (`drift`) pour les écrans de consultation, avec la date de mise à jour affichée. File d'écritures hors ligne en phase 3. |

### Équivalents gratuits des fonctions payantes
| Besoin | Option payante | Choix gratuit |
|---|---|---|
| Logique serveur, cron | Cloud Functions et Scheduler (Blaze) | RPC Postgres, pg_cron, Edge Functions |
| Fichiers | Cloud Storage (Blaze obligatoire depuis le 3 février 2026) | Supabase Storage |
| Push | — | FCM (gratuit) et notifications locales planifiées |
| SMS | Twilio, Africa's Talking (payant) | Messages WhatsApp pré-remplis (`wa.me`, gratuits, envoyés par le trésorier). SMS reporté en phase 3. |
| Connexion par téléphone (OTP) | SMS payants | Reportée. Email, Google et Apple en V1. |
| PDF (PV, relevés) | Serveur | Généré dans l'app (`pdf`, `printing`) à partir des chiffres calculés en base, puis empreinte SHA-256 enregistrée |
| Liens d'invitation, QR | Dynamic Links (arrêté) | App Links et Universal Links hébergés sur Cloudflare Pages (gratuit), QR via `qr_flutter` et `mobile_scanner` |
| Crashs, analytics | — | Firebase Crashlytics et Analytics (gratuits sur Spark) |
| Builds iOS sans Mac | — | Codemagic, offre gratuite (minutes macOS mensuelles) |

## 3. Multi-groupes et rôles
- Écran **« Mes groupes »** : liste des tontines et caisses, avec rôle et solde résumé. Sélecteur de groupe
  dans l'en-tête, groupe actif mémorisé.
- Rôles par groupe : `owner`, `president`, `treasurer`, `auditor`, `member` (cumulables).
  L'actuelle « administratrice » devient `owner` + `treasurer`.
- Le routeur ne dépend plus d'une tontine unique : `/groups`, puis `/g/:groupId/...`.
- Membres sans smartphone (EF-04) : `user_id NULL`, gérés par le trésorier.
- Créer ou rejoindre un groupe est toujours possible depuis « Mes groupes ».

## 4. Internationalisation
- `flutter gen-l10n` avec `lib/l10n/app_fr.arb` (modèle) et `app_en.arb`. Environ 720 chaînes à
  externaliser, écran par écran, avec un test qui échoue s'il manque une clé.
- Montants : `NumberFormat` selon la langue (`150 000 FCFA` / `150,000 FCFA`). Les dates suivent la langue.
- Messages d'erreur du domaine : codes → traductions (le domaine ne produit plus de texte).
- Fiches stores, captures, politique de confidentialité et CGU dans les deux langues.
- Notifications push traduites côté serveur selon `profiles.locale`.

## 5. Notifications
| Événement | Destinataires | Canal |
|---|---|---|
| Invitation acceptée, nouveau membre | Bureau | Push |
| Déclaration ou dépôt soumis | Trésorier, président | Push |
| Déclaration, dépôt ou paiement validé ou rejeté | Membre concerné | Push |
| Échéancier généré ou réorganisé | Tous | Push |
| Tour J-3 et jour J (cotisation due) | Membres du tour | Push et notification locale |
| Retard constaté, pénalité appliquée | Membre, avaliste, bureau | Push |
| Bénéficiaire du tour (« c'est ton tour ») | Bénéficiaire | Push |
| Prêt demandé, approuvé, refusé, décaissé | Emprunteur, signataires | Push |
| Échéance de prêt J-3 et jour J | Emprunteur | Push et notification locale |
| Cassation J-30, J-7, J-1 | Emprunteurs | Push |
| Résultat de cassation, PV disponible | Tous | Push |
| Règle modifiée (double validation) | Bureau | Push |
| Abonnement : échec de paiement, expiration | Propriétaire du groupe | Push |

Il y a aussi une boîte de réception dans l'app (table `notifications`) et des préférences par type.

## 6. Monétisation pilotée à distance
**Principe :** l'app ne contient aucune règle commerciale en dur. Au démarrage, elle lit `app_config`,
`feature_gates` et `ad_placements` (gardés en cache), et l'entitlement `premium` via RevenueCat.

- **RevenueCat** (gratuit jusqu'à un seuil de revenu mensuel ; vérifier le seuil à l'inscription) :
  produits stores, entitlement `premium`, offres et paywalls modifiables depuis son tableau de bord sans
  mise à jour de l'app. Un webhook vers une Edge Function met à jour `entitlements_cache` pour la RLS.
- **`feature_gates`** : `feature_key`, `enabled`, `free_limit`, `premium_limit`, `scope (user|group)`.
  Exemples : `max_groups`, `max_members_per_group`, `caisse_module`, `pdf_reports`, `excel_export`,
  `ads_free`. Les limites sont **aussi vérifiées dans les RPC**, et pas seulement dans l'UI.
- **Publicités (AdMob, `google_mobile_ads`)** :
  - Emplacements activables à distance (`ad_placements`) : bannière en bas des listes de consultation,
    native dans l'historique, et **vidéo récompensée** (« regarde une pub pour générer ce relevé PDF »).
  - **Jamais de pub** dans les parcours d'argent (dépôt, prêt, validation, cassation), ce qui protège la
    confiance et la conformité. Pas d'interstitiel.
  - Premium = sans publicité.
  - Consentement **UMP** (obligatoire pour les utilisateurs de la diaspora en UE et au Royaume-Uni),
    **ATT** sur iOS, identifiants `SKAdNetworkItems`, permission `AD_ID` sur Android, déclaration
    « Contient des annonces » sur Play.
- **Console propriétaire** : Flutter Web (même dépôt, cible `lib/owner_console/`), hébergée sur Cloudflare
  Pages, accès réservé au claim `platform_owner`. Elle sert à éditer les limites, activer ou désactiver
  les fonctions et les pubs, consulter les statistiques. Au départ, le Supabase Studio peut tenir ce rôle.

## 7. Autres fonctionnalités manquantes
- Suppression de compte (dans l'app et via une page web), avec anonymisation dans le grand livre.
- Profil modifiable, changement de mot de passe, choix de la langue.
- Quitter un groupe (soldes à régler d'abord).
- Mise à jour forcée ou suggérée (`app_config.min_version`).
- Aide et FAQ, contact support (lien WhatsApp), CGU et politique de confidentialité.
- Acceptation horodatée des règles du groupe (cahier des charges §12).
- Code PIN ou biométrie avant toute validation financière (`local_auth`), verrouillage après
  15 minutes d'inactivité sur les écrans du bureau.
- Demande d'avis dans le store (`in_app_review`) après une action réussie.
- Mode sombre (optionnel) : tokens déjà centralisés.
- iPhone en portrait uniquement.

## 8. Publication sur les stores
### Comptes (à créer)
- **Google Play** : 25 $ une fois. Un compte **personnel** créé après novembre 2023 doit faire un test
  fermé avec **12 testeurs pendant 14 jours d'affilée** avant la production. Un compte **organisation**
  (D-U-N-S gratuit, entité légale) en est exempté.
- **Apple Developer** : 99 $ par an. ⚠️ La guideline 5.1.1(ix) demande que les apps de services
  financiers soient publiées par une **entité légale**, pas par un particulier. Il est recommandé de créer
  une structure (association ou entreprise) et un D-U-N-S avant la soumission iOS.
- **Positionnement** : un « outil de tenue de registre ». L'app ne prête pas, ne détient pas d'argent et
  ne traite aucun paiement entre membres. Remplir la **déclaration des fonctionnalités financières** de
  Play en conséquence.

### Android
- `applicationId` et namespace `com.djanguibook.app` (à confirmer), libellé `DjanguiBook`.
- Keystore d'upload hors dépôt et `key.properties`, Play App Signing, build en AAB.
- **targetSdk 36** (obligatoire pour les nouvelles apps et mises à jour à partir du 31 août 2026).
- Permissions minimales (caméra via `image_picker`, `POST_NOTIFICATIONS`, `AD_ID`).
- Data Safety, classification du contenu, public cible (18 ans et plus), politique de confidentialité
  (URL), « Contient des annonces », achats intégrés.
- Fiches FR et EN, icône 512 px, bannière 1024×500, captures.

### iOS
- Bundle ID identique, `CFBundleDisplayName` = `DjanguiBook`, `InfoPlist.strings` FR et EN.
- **Build avec Xcode 26 et le SDK iOS 26** (obligatoire depuis le 28 avril 2026). Cible minimale iOS 15.
- Descriptions d'usage : caméra, photos, `NSUserTrackingUsageDescription` (ATT).
- `PrivacyInfo.xcprivacy`, capacités Push et Sign in with Apple, clé APNs envoyée à Firebase.
- Révocation du token Apple lors de la suppression de compte.
- App Privacy (« nutrition labels »), achats intégrés déclarés, compte de démonstration pour la review.

### Livraison continue (gratuite)
- GitHub Actions : `flutter analyze`, `flutter test`, tests pgTAP, migrations Supabase.
- Codemagic : builds signés Android et iOS, upload vers Play (test interne) et TestFlight.
- Environnements : `dev` (Supabase local via la CLI) et `prod`. Saveurs Flutter `dev` et `prod`.

## 9. Ordre de réalisation
| # | Lot | Contenu | Critère de sortie |
|---|---|---|---|
| 0 | Fondations | Renommage DjanguiBook et identifiants, i18n (socle et écrans existants), projet Supabase et CLI, CI, SessionStart hook (Flutter SDK) | App FR et EN compilée, `flutter analyze` propre |
| 1 | Migration | Schéma, RLS, RPC de la tontine rotative, nouveaux repositories `data/`, auth Supabase (email, Google, Apple), multi-groupes, Storage | Les 125 tests passent, les tests RLS couvrent les anciens cas (dont l'usurpation) |
| 2 | Plateforme | Push FCM, boîte de notifications, rappels pg_cron, suppression de compte, profil, mise à jour forcée, Crashlytics | Chaque événement du §5 déclenche une notification testée |
| 3 | Monétisation | RevenueCat, `feature_gates`, AdMob, UMP et ATT, console propriétaire | Basculer une fonction ou une pub dans la console agit sans mise à jour de l'app |
| 4 | Caisse : socle | Exercices, règles, grand livre, dépôts (phase 1 du cahier des charges) | Soldes égaux à la relecture du grand livre |
| 5 | Caisse : crédit et cassation | Prêts, pénalités, retraits, cassation, PV (phase 2) | Les 15 critères d'acceptation passent, §7.5 à l'identique |
| 6 | Publication | Comptes, fiches, test fermé Play (12 testeurs, 14 jours), TestFlight, soumissions | Apps publiées |
| 7 | Confort | Mobile Money, SMS, mode séance, hors ligne en écriture, export Excel (phase 3) | — |

## 10. Règles de la caisse à valider par un bureau pilote (valeurs proposées)
1. Exemple §7.5 : compter le mois du dépôt comme un mois entier (le jeu de référence passe en capital-mois).
2. Frais : sortis de la caisse au fil de l'exercice (écriture `frais`), donc non soustraits une seconde
   fois dans le contrôle de cohérence.
3. Bénéfice négatif (impayé irrécouvrable) : perte répartie au prorata du capital-jour, sans jamais rendre
   un solde d'épargne négatif.
4. Réserve et reliquat d'arrondi : propriété du groupe, reportés comme « solde d'ouverture » de l'exercice
   suivant.
5. Pénalité de retard : calculée sur l'intérêt échu impayé (pas sur le capital), 1 % par jour, plafond 10 %.
6. Dernière période après la cassation : période raccourcie, intérêt au prorata. P = nombre réel de jours
   de la période.
7. Quatre yeux : il faut deux personnes distinctes au bureau. Le prêt du président est approuvé par le
   trésorier et le commissaire.
8. Épargne servant de garantie : épargne bloquée = encours ÷ multiplicateur de plafond.
9. Règles après ouverture : double validation président + trésorier, historisée.
10. Plusieurs prêts simultanés : oui, sous le même plafond global. Membre sans épargne : ne peut pas
    emprunter.
