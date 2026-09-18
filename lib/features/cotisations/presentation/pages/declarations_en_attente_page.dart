import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../domain/entities/declaration.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/nom.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../echeancier/application/echeancier_providers.dart';
import '../../../membres/application/membres_providers.dart';
import '../../application/cotisations_providers.dart';
import '../widgets/declaration_card.dart';

/// Onglet Déclarations : toutes les déclarations de paiement (en attente,
/// validées, contestées), groupées par tour — le tour le plus récent en
/// tête, chaque groupe listant ses déclarations en attente d'abord. Ouvert
/// en lecture seule aux membres ; seule l'administratrice peut, en ouvrant
/// une déclaration en attente, la valider ou la refuser (voir
/// `DetailDeclarationPage`).
class DeclarationsEnAttentePage extends ConsumerWidget {
  const DeclarationsEnAttentePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final declarationsAsync = ref.watch(declarationsProvider);
    final nomsAsync = ref.watch(nomsProvider);
    final membresAsync = ref.watch(membresProvider);
    final toursAsync = ref.watch(toursProvider);

    final chargement = [declarationsAsync, nomsAsync, membresAsync, toursAsync]
        .any((a) => a.isLoading && !a.hasValue);
    final enErreur =
        [declarationsAsync, nomsAsync, membresAsync, toursAsync].any((a) => a.hasError);

    return AppScaffold(
      selectedNavIndex: 3,
      appBar: AppBar(title: const Text('Déclarations')),
      body: enErreur
          ? ErrorView(
              message: 'Impossible de charger les déclarations.',
              onRetry: () {
                ref.invalidate(declarationsProvider);
                ref.invalidate(nomsProvider);
                ref.invalidate(membresProvider);
                ref.invalidate(toursProvider);
              },
            )
          : chargement
              ? const LoadingView()
              : _Contenu(
                  declarations: declarationsAsync.value ?? const [],
                  noms: nomsAsync.value ?? const [],
                  membres: membresAsync.value ?? const [],
                  tours: toursAsync.value ?? const [],
                ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.declarations,
    required this.noms,
    required this.membres,
    required this.tours,
  });

  final List<Declaration> declarations;
  final List<Nom> noms;
  final List<Membre> membres;
  final List<Tour> tours;

  Nom? _nom(String nomId) {
    for (final nom in noms) {
      if (nom.id == nomId) return nom;
    }
    return null;
  }

  Membre? _membre(String membreId) {
    for (final membre in membres) {
      if (membre.id == membreId) return membre;
    }
    return null;
  }

  Tour? _tour(String tourId) {
    for (final tour in tours) {
      if (tour.id == tourId) return tour;
    }
    return null;
  }

  String _beneficiaires(Tour tour) {
    final nom = _nom(tour.nomId);
    if (nom == null) return 'Nom inconnu';
    final noms = <String>[];
    for (final part in nom.parts) {
      final membre = _membre(part.membreId);
      if (membre != null) noms.add(membre.nomComplet);
    }
    return noms.isEmpty ? nom.libelle : noms.join(' & ');
  }

  int _comparerDeclarations(Declaration a, Declaration b) {
    final aEnAttente = a.statut.name == 'enAttente';
    final bEnAttente = b.statut.name == 'enAttente';
    if (aEnAttente != bEnAttente) return aEnAttente ? -1 : 1;
    return b.datePaiement.compareTo(a.datePaiement);
  }

  @override
  Widget build(BuildContext context) {
    if (declarations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Aucune déclaration pour le moment.',
            style: AppTypography.secondary,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Groupées par tour, le tour le plus récent en tête ; au sein d'un
    // groupe, les déclarations en attente d'abord (les plus actionnables
    // pour l'administratrice), puis les autres par date décroissante. Les
    // déclarations dont le tour n'existe plus atterrissent dans un groupe
    // « Tour inconnu » en fin de liste plutôt que d'être perdues.
    final parTour = <String, List<Declaration>>{};
    for (final declaration in declarations) {
      parTour.putIfAbsent(declaration.tourId, () => []).add(declaration);
    }
    final groupes = parTour.entries
        .map((entree) => (
              tour: _tour(entree.key),
              declarations: entree.value..sort(_comparerDeclarations),
            ))
        .toList()
      ..sort((a, b) {
        if (a.tour == null || b.tour == null) {
          return a.tour == null ? 1 : -1;
        }
        return b.tour!.position.compareTo(a.tour!.position);
      });

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        children: [
          for (final groupe in groupes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _GroupeTour(
                titre: groupe.tour == null
                    ? 'Tour inconnu'
                    : 'Tour ${groupe.tour!.position} — ${_beneficiaires(groupe.tour!)}',
                declarations: groupe.declarations,
                membre: _membre,
                nom: _nom,
              ),
            ),
        ],
      ),
    );
  }
}

/// Section accordéon d'un tour : repliée par défaut, sauf si elle contient
/// au moins une déclaration en attente (les plus actionnables pour
/// l'administratrice restent visibles sans manipulation).
class _GroupeTour extends StatelessWidget {
  const _GroupeTour({
    required this.titre,
    required this.declarations,
    required this.membre,
    required this.nom,
  });

  final String titre;
  final List<Declaration> declarations;
  final Membre? Function(String membreId) membre;
  final Nom? Function(String nomId) nom;

  @override
  Widget build(BuildContext context) {
    final enAttente = declarations.where((d) => d.statut.name == 'enAttente').length;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: enAttente > 0,
          title: Text(titre, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            enAttente > 0
                ? '$enAttente en attente sur ${declarations.length}'
                : '${declarations.length} déclaration${declarations.length > 1 ? 's' : ''}',
            style: AppTypography.secondary,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
          children: [
            for (final declaration in declarations)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: DeclarationCard(
                  declaration: declaration,
                  membre: membre(declaration.membreId),
                  nom: nom(declaration.nomId),
                  onTap: () => context.go('${AppRouter.declarationsPath}/${declaration.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
