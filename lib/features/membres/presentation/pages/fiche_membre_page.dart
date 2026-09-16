import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/services/calculateur_cotisation.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_controller.dart';
import '../../application/membres_providers.dart';
import '../widgets/membre_form.dart';
import '../widgets/parts_editor.dart';

/// Fiche d'un membre : coordonnées, noms détenus et montant dû par
/// échéance, avec actions de modification et d'activation/désactivation.
class FicheMembrePage extends ConsumerStatefulWidget {
  const FicheMembrePage({required this.membreId, super.key});

  final String membreId;

  @override
  ConsumerState<FicheMembrePage> createState() => _FicheMembrePageState();
}

class _FicheMembrePageState extends ConsumerState<FicheMembrePage> {
  var _modification = false;

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _modifier(String tontineId, Membre membre, MembreFormValue valeur) async {
    try {
      await ref.read(membresControllerProvider.notifier).modifierMembre(
            tontineId: tontineId,
            membre: membre,
            nomComplet: valeur.nomComplet,
            email: valeur.email,
            whatsapp: valeur.whatsapp,
          );
      if (mounted) {
        setState(() => _modification = false);
        _message('Coordonnées mises à jour.');
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  Future<void> _basculerActif(String tontineId, Membre membre) async {
    try {
      final notifier = ref.read(membresControllerProvider.notifier);
      if (membre.actif) {
        await notifier.desactiverMembre(tontineId: tontineId, membre: membre);
        if (mounted) _message('${membre.nomComplet} a été désactivé(e).');
      } else {
        await notifier.reactiverMembre(tontineId: tontineId, membre: membre);
        if (mounted) _message('${membre.nomComplet} a été réactivé(e).');
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membresAsync = ref.watch(membresProvider);
    final tontineId = ref.watch(currentTontineIdProvider);

    if (membresAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
            onPressed: () => context.go(AppRouter.membresPath),
          ),
        ),
        body: ErrorView(
          message: 'Impossible de charger ce membre.',
          onRetry: () => ref.invalidate(membresProvider),
        ),
      );
    }
    if (membresAsync.isLoading && !membresAsync.hasValue || tontineId == null) {
      return const Scaffold(body: LoadingView());
    }

    final membres = membresAsync.value ?? const <Membre>[];
    Membre? membre;
    for (final candidat in membres) {
      if (candidat.id == widget.membreId) {
        membre = candidat;
        break;
      }
    }
    if (membre == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
            onPressed: () => context.go(AppRouter.membresPath),
          ),
        ),
        body: const ErrorView(message: 'Ce membre est introuvable.'),
      );
    }
    final tontine = ref.watch(tontineProvider).value;
    final noms = ref.watch(nomsProvider).value ?? const <Nom>[];
    final busy = ref.watch(membresControllerProvider).isLoading;
    final membreActuel = membre;

    final nomsDetenus = [
      for (final nom in noms)
        for (final part in nom.parts)
          if (part.membreId == membreActuel.id) (nom: nom, fraction: part.fraction),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: _modification
              ? () => setState(() => _modification = false)
              : () => context.go(AppRouter.membresPath),
        ),
        title: Text(membreActuel.nomComplet),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: _modification
                ? MembreForm(
                    nomComplet: membreActuel.nomComplet,
                    email: membreActuel.email ?? '',
                    whatsapp: membreActuel.whatsapp ?? '',
                    submitLabel: 'Enregistrer',
                    busy: busy,
                    onSubmit: (valeur) => _modifier(tontineId, membreActuel, valeur),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!membreActuel.actif)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                              SizedBox(width: AppSpacing.xs),
                              Text('Membre désactivé', style: AppTypography.secondary),
                            ],
                          ),
                        ),
                      if (membreActuel.whatsapp != null)
                        _ligneContact(Icons.chat, membreActuel.whatsapp!),
                      if (membreActuel.email != null)
                        _ligneContact(Icons.mail_outline, membreActuel.email!),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Noms détenus',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (nomsDetenus.isEmpty)
                        const Text('Aucun nom attribué pour le moment.', style: AppTypography.secondary)
                      else
                        Card(
                          child: Column(
                            children: [
                              for (final detenu in nomsDetenus)
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.canvas,
                                    child: Text(formatFraction(detenu.fraction), style: AppTypography.micro),
                                  ),
                                  title: Text(detenu.nom.libelle),
                                ),
                            ],
                          ),
                        ),
                      if (tontine != null && nomsDetenus.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _carteMontantDu(tontine, membreActuel, nomsDetenus),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Modifier les coordonnées',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => setState(() => _modification = true),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: membreActuel.actif ? 'Désactiver ce membre' : 'Réactiver ce membre',
                        variant: AppButtonVariant.destructive,
                        busy: busy,
                        onPressed: busy ? null : () => _basculerActif(tontineId, membreActuel),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _ligneContact(IconData icon, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate),
          const SizedBox(width: AppSpacing.xs),
          Text(valeur, style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _carteMontantDu(
    Tontine tontine,
    Membre membre,
    List<({Nom nom, double fraction})> nomsDetenus,
  ) {
    const calculateur = CalculateurCotisation();
    final total = nomsDetenus.fold<int>(
      0,
      (somme, detenu) => somme +
          calculateur.calculerMontantDuPourMembre(
            tontine: tontine,
            nom: detenu.nom,
            membreId: membre.id,
          ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dû par échéance', style: AppTypography.secondary),
            const SizedBox(height: 4),
            Text('$total FCFA', style: AppTypography.amount),
          ],
        ),
      ),
    );
  }
}
