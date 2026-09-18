import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/rules/validation_parts.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../echeancier/application/echeancier_controller.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_providers.dart';
import '../widgets/nombre_de_noms_field.dart' show formatterNombreDeNoms;
import '../widgets/parts_editor.dart';

/// Liste des membres et des noms de la tontine courante, avec les actions
/// d'ajout, d'attribution des parts et de génération de l'échéancier une
/// fois tous les noms répartis.
class MembresPage extends ConsumerWidget {
  const MembresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlashMessageListener.attach(ref, context);
    final membresAsync = ref.watch(membresProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final noms = nomsAsync.value ?? const [];
    final membres = membresAsync.value ?? const [];
    final isAdmin = ref.watch(isAdminProvider);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        selectedNavIndex: 1,
        appBar: AppBar(
          title: const Text('Membres'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Noms (${noms.length})'),
              Tab(text: 'Membres (${membres.length})'),
            ],
          ),
        ),
        floatingActionButton: !isAdmin
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.go('${AppRouter.membresPath}/ajouter'),
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.ink,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
        body: membresAsync.hasError || nomsAsync.hasError
            ? ErrorView(
                message: 'Impossible de charger les membres.',
                onRetry: () {
                  ref.invalidate(membresProvider);
                  ref.invalidate(nomsProvider);
                },
              )
            : (membresAsync.isLoading || nomsAsync.isLoading) &&
                    !membresAsync.hasValue &&
                    !nomsAsync.hasValue
                ? const LoadingView()
                : _Contenu(membres: membres, noms: noms, isAdmin: isAdmin),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.membres, required this.noms, required this.isAdmin});

  final List<Membre> membres;
  final List<Nom> noms;
  final bool isAdmin;

  double _totalParts(String membreId) {
    var total = 0.0;
    for (final nom in noms) {
      for (final part in nom.parts) {
        if (part.membreId == membreId) total += part.fraction;
      }
    }
    return total;
  }

  Future<void> _genererEcheancier(BuildContext context, WidgetRef ref) async {
    final tontine = ref.read(tontineProvider).value;
    if (tontine == null) return;
    try {
      await ref
          .read(echeancierControllerProvider.notifier)
          .genererEcheancier(tontine: tontine, noms: noms);
      if (context.mounted) context.go(AppRouter.accueilPath);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tours = ref.watch(toursProvider).value ?? const [];
    final tontine = ref.watch(tontineProvider).value;
    final busyEcheancier = ref.watch(echeancierControllerProvider).isLoading;

    final actifs = membres.where((m) => m.actif).toList(growable: false);
    final inactifs = membres.where((m) => !m.actif).toList(growable: false);

    final tousLesNomsValides = noms.isNotEmpty &&
        noms.every((nom) => const ValidationParts().estValide(nom.parts));
    final quotaAtteint = tontine != null && noms.length >= tontine.nombreDeNoms;
    final peutGenerer = tousLesNomsValides && quotaAtteint && tours.isEmpty;

    return SafeArea(
      child: TabBarView(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
            children: [
              if (tontine != null) ...[
                Text(
                  '${noms.length}/${tontine.nombreDeNoms} noms attribués',
                  style: AppTypography.secondary,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (isAdmin && !quotaAtteint) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Attribuer',
                    icon: Icons.add,
                    variant: AppButtonVariant.tertiary,
                    onPressed: () => context.go('${AppRouter.membresPath}/noms/nouveau'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (noms.isEmpty)
                const _CarteVide(
                  message: "Aucun nom n'a encore été créé. Attribuez le premier pour commencer.",
                )
              else
                ...noms.map(
                  (nom) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _NomCard(
                      nom: nom,
                      membres: membres,
                      onTap: !isAdmin
                          ? null
                          : () => context.go('${AppRouter.membresPath}/noms/${nom.id}'),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (isAdmin && peutGenerer)
                AppButton(
                  label: 'Générer l\'échéancier',
                  icon: Icons.event_available_outlined,
                  variant: AppButtonVariant.accent,
                  busy: busyEcheancier,
                  onPressed: busyEcheancier ? null : () => _genererEcheancier(context, ref),
                )
              else if (isAdmin && tousLesNomsValides && !quotaAtteint && tours.isEmpty && tontine != null)
                _CarteVide(
                  message: 'Encore ${tontine.nombreDeNoms - noms.length} nom(s) à attribuer avant '
                      "de pouvoir générer l'échéancier.",
                ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
            children: [
              Text('Membres actifs (${actifs.length})', style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.sm),
              if (actifs.isEmpty)
                const _CarteVide(message: 'Aucun membre actif pour le moment.')
              else
                ...actifs.map(
                  (membre) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MembreCard(
                      membre: membre,
                      totalParts: _totalParts(membre.id),
                      onTap: () => context.go('${AppRouter.membresPath}/${membre.id}'),
                    ),
                  ),
                ),
              if (inactifs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Membres désactivés (${inactifs.length})', style: AppTypography.screenTitle),
                const SizedBox(height: AppSpacing.sm),
                ...inactifs.map(
                  (membre) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MembreCard(
                      membre: membre,
                      totalParts: _totalParts(membre.id),
                      onTap: () => context.go('${AppRouter.membresPath}/${membre.id}'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NomCard extends StatelessWidget {
  const _NomCard({required this.nom, required this.membres, required this.onTap});

  final Nom nom;
  final List<Membre> membres;
  final VoidCallback? onTap;

  String _nomComplet(String membreId) {
    for (final membre in membres) {
      if (membre.id == membreId) return membre.nomComplet;
    }
    return 'Membre inconnu';
  }

  @override
  Widget build(BuildContext context) {
    final sommeValide = const ValidationParts().estValide(nom.parts);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.canvas,
                child: Icon(Icons.badge_outlined, color: AppColors.indigo, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom.libelle, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      nom.parts.isEmpty
                          ? 'Aucun détenteur'
                          : nom.parts
                              .map((p) => '${formatFraction(p.fraction)} ${_nomComplet(p.membreId)}')
                              .join(', '),
                      style: AppTypography.secondary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!sommeValide)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                ),
              const Icon(Icons.chevron_right, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembreCard extends StatelessWidget {
  const _MembreCard({required this.membre, required this.totalParts, required this.onTap});

  final Membre membre;
  final double totalParts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enAttente = membre.uid == null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.canvas,
                child: Text(
                  _initiales(membre.nomComplet),
                  style: AppTypography.secondary.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(membre.nomComplet, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      membre.whatsapp ?? membre.email ?? 'Aucun contact',
                      style: AppTypography.secondary,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                    child: Text(
                      formatterNombreDeNoms(totalParts),
                      style: AppTypography.micro.copyWith(color: AppColors.indigo),
                    ),
                  ),
                  if (enAttente) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      child: const Text('En attente', style: AppTypography.micro),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }

  String _initiales(String nom) {
    final mots = nom.trim().split(RegExp(r'\s+'));
    if (mots.isEmpty || mots.first.isEmpty) return '?';
    final premiere = mots.first[0];
    final derniere = mots.length > 1 ? mots.last[0] : '';
    return (premiere + derniere).toUpperCase();
  }
}

class _CarteVide extends StatelessWidget {
  const _CarteVide({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message, style: AppTypography.secondary),
      ),
    );
  }
}
