import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/declaration.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/cotisations_providers.dart';
import '../../application/declaration_controller.dart';

/// Détail d'une déclaration de paiement, avec preuve. Les actions de
/// traitement (validation ou refus) ne sont visibles que pour
/// l'administratrice, sur une déclaration encore en attente — les membres
/// consultent cet écran en lecture seule.
class DetailDeclarationPage extends ConsumerWidget {
  const DetailDeclarationPage({required this.declarationId, super.key});

  final String declarationId;

  Future<void> _valider(
    BuildContext context,
    WidgetRef ref,
    String tontineId,
    Declaration declaration,
    Tontine tontine,
    Nom nom,
    Tour tour,
  ) async {
    final adminUid = ref.read(sessionProvider).value?.utilisateur.uid;
    if (adminUid == null) return;
    try {
      await ref.read(declarationControllerProvider.notifier).validerDeclaration(
            tontineId: tontineId,
            declaration: declaration,
            tontine: tontine,
            nom: nom,
            tour: tour,
            adminUid: adminUid,
          );
      if (context.mounted) {
        ref.read(flashMessageProvider.notifier).set('Déclaration validée.');
        context.go(AppRouter.declarationsPath);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  Future<void> _refuser(
    BuildContext context,
    WidgetRef ref,
    String tontineId,
    Declaration declaration,
  ) async {
    final motif = await showDialog<String>(
      context: context,
      builder: (context) => const _MotifRefusDialog(),
    );
    if (motif == null || !context.mounted) return;
    try {
      await ref.read(declarationControllerProvider.notifier).refuserDeclaration(
            tontineId: tontineId,
            declaration: declaration,
            motif: motif,
          );
      if (context.mounted) {
        ref.read(flashMessageProvider.notifier).set('Déclaration refusée.');
        context.go(AppRouter.declarationsPath);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageErreurAuth(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tontineId = ref.watch(currentTontineIdProvider);
    final tontineAsync = ref.watch(tontineProvider);
    final declarationsAsync = ref.watch(declarationsProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final membresAsync = ref.watch(membresProvider);
    final toursAsync = ref.watch(toursProvider);

    final chargement = [tontineAsync, declarationsAsync, nomsAsync, membresAsync, toursAsync]
        .any((a) => a.isLoading && !a.hasValue);
    final enErreur =
        [tontineAsync, declarationsAsync, nomsAsync, membresAsync, toursAsync].any((a) => a.hasError);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => context.go(AppRouter.declarationsPath),
        ),
        title: const Text('Déclaration'),
      ),
      body: enErreur
          ? ErrorView(
              message: 'Impossible de charger cette déclaration.',
              onRetry: () {
                ref.invalidate(tontineProvider);
                ref.invalidate(declarationsProvider);
                ref.invalidate(nomsProvider);
                ref.invalidate(membresProvider);
                ref.invalidate(toursProvider);
              },
            )
          : chargement
              ? const LoadingView()
              : _Contenu(
                  declarationId: declarationId,
                  tontineId: tontineId,
                  tontine: tontineAsync.value,
                  declarations: declarationsAsync.value ?? const [],
                  noms: nomsAsync.value ?? const [],
                  membres: membresAsync.value ?? const [],
                  tours: toursAsync.value ?? const [],
                  isAdmin: ref.watch(isAdminProvider),
                  monMembreId: ref.watch(sessionProvider).value?.profil?.membreId,
                  onValider: (declaration, tontine, nom, tour) =>
                      _valider(context, ref, tontineId!, declaration, tontine, nom, tour),
                  onRefuser: (declaration) => _refuser(context, ref, tontineId!, declaration),
                ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.declarationId,
    required this.tontineId,
    required this.tontine,
    required this.declarations,
    required this.noms,
    required this.membres,
    required this.tours,
    required this.isAdmin,
    required this.monMembreId,
    required this.onValider,
    required this.onRefuser,
  });

  final String declarationId;
  final String? tontineId;
  final Tontine? tontine;
  final List<Declaration> declarations;
  final List<Nom> noms;
  final List<Membre> membres;
  final List<Tour> tours;
  final bool isAdmin;
  final String? monMembreId;
  final void Function(Declaration declaration, Tontine tontine, Nom nom, Tour tour) onValider;
  final void Function(Declaration declaration) onRefuser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Declaration? declaration;
    for (final candidat in declarations) {
      if (candidat.id == declarationId) {
        declaration = candidat;
        break;
      }
    }
    if (declaration == null || tontine == null || tontineId == null) {
      return const ErrorView(message: 'Cette déclaration est introuvable.');
    }

    Nom? nom;
    for (final candidat in noms) {
      if (candidat.id == declaration.nomId) nom = candidat;
    }
    Membre? membre;
    for (final candidat in membres) {
      if (candidat.id == declaration.membreId) membre = candidat;
    }
    Tour? tour;
    for (final candidat in tours) {
      if (candidat.id == declaration.tourId) tour = candidat;
    }

    final busy = ref.watch(declarationControllerProvider).isLoading;
    final peutTraiter =
        isAdmin && declaration.statut.name == 'enAttente' && nom != null && tour != null;
    // Une déclaration refusée ou validée partiellement (montant inférieur
    // au montant dû) n'empêche pas l'auteur d'en refaire une : les règles
    // Firestore n'autorisent de toute façon qu'à *créer* une nouvelle
    // déclaration, jamais à modifier celle-ci. L'écran de dépôt
    // (`DeclarerPaiementPage`) reste seul juge de l'éligibilité réelle
    // (tour toujours en cours, reste à devoir) : ce bouton n'est qu'un
    // raccourci.
    final peutRedeclarer = !isAdmin &&
        monMembreId != null &&
        monMembreId == declaration.membreId &&
        declaration.statut.name != 'enAttente';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(membre?.nomComplet ?? 'Membre inconnu', style: AppTypography.screenTitle),
              const SizedBox(height: 2),
              Text(nom?.libelle ?? 'Nom inconnu', style: AppTypography.secondary),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ligne('Montant déclaré', '${declaration.montantDeclare} FCFA'),
                      const SizedBox(height: AppSpacing.xs),
                      _ligne('Date de paiement', _formatDate(declaration.datePaiement)),
                      const SizedBox(height: AppSpacing.xs),
                      _ligne('Statut', _libelleStatut(declaration.statut.name)),
                      if (declaration.motifContestation != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _ligne('Motif du refus', declaration.motifContestation!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Preuve', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              _CartePreuve(preuveId: declaration.preuveId),
              if (peutTraiter) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Valider la déclaration',
                  variant: AppButtonVariant.accent,
                  busy: busy,
                  onPressed: busy ? null : () => onValider(declaration!, tontine!, nom!, tour!),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Refuser',
                  variant: AppButtonVariant.destructive,
                  busy: busy,
                  onPressed: busy ? null : () => onRefuser(declaration!),
                ),
              ],
              if (peutRedeclarer) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Faire une nouvelle déclaration',
                  variant: AppButtonVariant.accent,
                  onPressed: () => context.go(
                    '${AppRouter.espaceMembrePath}/declarer/${declaration!.nomId}',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ligne(String label, String valeur) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.secondary)),
        Flexible(
          child: Text(
            valeur,
            style: AppTypography.body,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _libelleStatut(String statut) => switch (statut) {
        'enAttente' => 'En attente',
        'validee' => 'Validée',
        _ => 'Contestée',
      };
}

class _CartePreuve extends ConsumerWidget {
  const _CartePreuve({required this.preuveId});

  final String preuveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preuveAsync = ref.watch(preuveProvider(preuveId));
    return preuveAsync.when(
      loading: () => const Card(
        child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: LoadingView()),
      ),
      error: (_, _) => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Impossible de charger la preuve.', style: AppTypography.secondary),
        ),
      ),
      data: (preuve) => preuve == null
          ? const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('Aucune preuve disponible.', style: AppTypography.secondary),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              child: Image.memory(
                base64Decode(preuve.imageEncodee),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _MotifRefusDialog extends StatefulWidget {
  const _MotifRefusDialog();

  @override
  State<_MotifRefusDialog> createState() => _MotifRefusDialogState();
}

class _MotifRefusDialogState extends State<_MotifRefusDialog> {
  final _motif = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  void _confirmer() {
    final valeur = _motif.text.trim();
    if (valeur.isEmpty) {
      setState(() => _erreur = 'Indiquez la raison du refus.');
      return;
    }
    Navigator.of(context).pop(valeur);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refuser cette déclaration'),
      content: TextField(
        controller: _motif,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Ex. preuve illisible, montant incorrect…',
          errorText: _erreur,
        ),
        onChanged: (_) {
          if (_erreur != null) setState(() => _erreur = null);
        },
      ),
      actions: [
        AppButton(
          label: 'Annuler',
          variant: AppButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Confirmer',
          variant: AppButtonVariant.destructive,
          onPressed: _confirmer,
        ),
      ],
    );
  }
}
