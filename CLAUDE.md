# DjanguiBook

App Flutter (Riverpod, go_router, Firebase) de gestion de tontines. Interface en français.

## Design — exigence « designer senior »

Pour tout travail sur l'interface (écran, widget, thème, animation dans `lib/`) :

1. Charger d'abord la skill `flutter-design-bridge` : elle traduit en Flutter les règles des skills web
   et fixe les apps de référence (Wave, Revolut, Cash App, Lydia, Linear…).
2. Puis la skill adaptée à la tâche :
   - philosophie, finitions, revue d'UI → `emil-design-eng`
   - nouvelle animation → `animate` · revue d'une animation → `review-animations`
   - audit global du mouvement → `improve-animations` · trouver où animer → `find-animation-opportunities`
   - gestes, springs, profondeur, typographie fine → `apple-design`
   - refonte d'un écran existant → `redesign-skill` · direction visuelle → `taste-skill`, `soft-skill`, `minimalist-skill`
   - tester avec des données extrêmes → `break-ui`
3. Tokens uniquement depuis `lib/app/theme.dart` (`AppColors`, `AppSpacing`, `AppTypography`, `AppTheme`).
4. Vérifier le rendu réel avec le MCP `dart` (lancer l'app, hot reload, inspecteur, tests), et partir des
   maquettes via le MCP `figma` quand un lien Figma est fourni.

## Commandes

- Tests : `flutter test`
- Analyse : `flutter analyze`
- Base de données (pgTAP, sans Docker) : `supabase/tests/run_local.sh`
- Repositories Supabase et Edge Functions contre PostgREST : `supabase/tests/run_api_local.sh`
- Edge Functions (Deno) : `cd supabase/functions && deno test tests/*.ts`

## Backend

Supabase (Postgres + RLS) : schéma et fonctions dans `supabase/migrations/`. Toute écriture sensible passe
par la RLS ou une fonction SQL ; chaque nouvelle règle d'accès a son test pgTAP dans `supabase/tests/database/`.
