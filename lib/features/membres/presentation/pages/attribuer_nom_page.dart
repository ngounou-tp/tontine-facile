import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/part.dart';
import '../../../../domain/rules/validation_parts.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_controller.dart';
import '../../application/membres_providers.dart';
import '../widgets/parts_editor.dart';

/// Crée un nouveau nom (part/tour) et lui attribue des détenteurs, ou
/// réattribue les parts d'un nom existant si [nomId] est fourni.
///
/// Le libellé n'est jamais saisi : il est toujours généré comme
/// « Nom [position] » (voir `MembresController.creerNom`) — la plupart des
/// noms sont de toute façon déjà attribués automatiquement à l'inscription
/// (voir `AjouterMembrePage`) ; cet écran sert surtout à corriger une
/// répartition (compléter un nom à moitié attribué, en créer un
/// manuellement).
class AttribuerNomPage extends ConsumerStatefulWidget {
  const AttribuerNomPage({this.nomId, super.key});

  final String? nomId;

  @override
  ConsumerState<AttribuerNomPage> createState() => _AttribuerNomPageState();
}

class _AttribuerNomPageState extends ConsumerState<AttribuerNomPage> {
  List<Part> _parts = const [];
  var _partsInitialisees = false;

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _enregistrer(String tontineId, Nom? nomExistant, int prochainePosition) async {
    if (!const ValidationParts().estValide(_parts)) {
      _message('La somme des parts doit être égale à 100 %.');
      return;
    }
    try {
      final notifier = ref.read(membresControllerProvider.notifier);
      if (nomExistant == null) {
        await notifier.creerNom(
          tontineId: tontineId,
          position: prochainePosition,
          parts: _parts,
        );
      } else {
        await notifier.assignerParts(tontineId: tontineId, nom: nomExistant, parts: _parts);
      }
      if (mounted) {
        ref.read(flashMessageProvider.notifier).set('Parts enregistrées.');
        context.go(AppRouter.membresPath);
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tontineId = ref.watch(currentTontineIdProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final membresActifs = (ref.watch(membresProvider).value ?? const <Membre>[])
        .where((m) => m.actif)
        .toList(growable: false);
    final busy = ref.watch(membresControllerProvider).isLoading;
    final tontineDemarree = (ref.watch(toursProvider).value ?? const []).isNotEmpty;

    if (nomsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour',
            onPressed: () => context.go(AppRouter.membresPath),
          ),
        ),
        body: ErrorView(
          message: 'Impossible de charger les noms.',
          onRetry: () => ref.invalidate(nomsProvider),
        ),
      );
    }
    // En mode édition, on attend que la liste des noms soit chargée avant de
    // construire le formulaire : sinon PartsEditor initialiserait son état
    // interne (sélection, pourcentages) avec une sélection vide, et ne se
    // resynchroniserait pas quand les vraies parts arrivent ensuite (il ne
    // relit `initialParts` qu'à sa création).
    if ((widget.nomId != null && nomsAsync.isLoading && !nomsAsync.hasValue) ||
        tontineId == null) {
      return const Scaffold(body: LoadingView());
    }

    final noms = nomsAsync.value ?? const <Nom>[];
    Nom? nomExistant;
    if (widget.nomId != null) {
      for (final candidat in noms) {
        if (candidat.id == widget.nomId) {
          nomExistant = candidat;
          break;
        }
      }
      if (nomExistant == null) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Retour',
              onPressed: () => context.go(AppRouter.membresPath),
            ),
          ),
          body: const ErrorView(message: 'Ce nom est introuvable.'),
        );
      }
    }

    if (!_partsInitialisees) {
      _parts = nomExistant?.parts ?? const [];
      _partsInitialisees = true;
    }

    final libelle = nomExistant?.libelle ?? 'Nom ${noms.length + 1}';
    final sommeValide = const ValidationParts().estValide(_parts) && _parts.isNotEmpty;
    // Les parts d'un nom déjà généré dans l'échéancier ne peuvent plus
    // changer : le montant dû de chaque détentrice est calculé en direct à
    // partir de `nom.parts` (voir CalculateurCotisation), donc les modifier
    // fausserait rétroactivement les tours déjà en cours ou remis.
    final verrouille = nomExistant != null && tontineDemarree;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => context.go(AppRouter.membresPath),
        ),
        title: Text(nomExistant == null ? 'Nouveau nom' : 'Modifier les parts'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(libelle, style: AppTypography.screenTitle),
                const SizedBox(height: AppSpacing.lg),
                if (verrouille)
                  _PartsVerrouillees(nom: nomExistant, membres: ref.watch(membresProvider).value ?? const [])
                else if (membresActifs.isEmpty)
                  const Text(
                    "Ajoutez d'abord des membres actifs pour pouvoir leur attribuer ce nom.",
                    style: AppTypography.secondary,
                  )
                else
                  PartsEditor(
                    membres: membresActifs,
                    initialParts: nomExistant?.parts ?? const [],
                    onChanged: (parts) => setState(() => _parts = parts),
                  ),
                if (!verrouille) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Enregistrer',
                    variant: AppButtonVariant.accent,
                    busy: busy,
                    onPressed: (busy || !sommeValide)
                        ? null
                        : () => _enregistrer(tontineId, nomExistant, noms.length + 1),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartsVerrouillees extends StatelessWidget {
  const _PartsVerrouillees({required this.nom, required this.membres});

  final Nom nom;
  final List<Membre> membres;

  String _nomComplet(String membreId) {
    for (final membre in membres) {
      if (membre.id == membreId) return membre.nomComplet;
    }
    return 'Membre inconnu';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: AppColors.canvas,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.slate),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    "Figé — l'échéancier a déjà démarré. Modifier ces parts fausserait les "
                    'montants dus déjà calculés.',
                    style: AppTypography.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final part in nom.parts)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.canvas,
                    child: Text(formatFraction(part.fraction), style: AppTypography.micro),
                  ),
                  title: Text(_nomComplet(part.membreId)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
