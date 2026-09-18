import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../tontine/application/tontine_providers.dart';
import '../../application/membres_controller.dart';
import '../../application/membres_providers.dart';
import '../widgets/membre_form.dart';
import '../widgets/nombre_de_noms_field.dart';
import '../widgets/parts_editor.dart';

/// Fiche d'un membre : coordonnées, code d'invitation, noms détenus et
/// montant dû par échéance, avec actions de modification, d'attribution de
/// noms supplémentaires et d'activation/désactivation.
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

  Future<void> _copierCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) _message('Code copié.');
  }

  Future<void> _attribuerNoms(String tontineId, Membre membre) async {
    final choix = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (sheetContext) => _FeuilleAttribuerNoms(nomComplet: membre.nomComplet),
    );
    if (choix == null || choix <= 0 || !mounted) return;
    try {
      await ref.read(membresControllerProvider.notifier).attribuerNomsSupplementaires(
            tontineId: tontineId,
            membreId: membre.id,
            nombreDeNoms: choix,
          );
      if (mounted) {
        _message('${formatterNombreDeNoms(choix)} attribué(s) à ${membre.nomComplet}.');
      }
    } catch (error) {
      if (mounted) _message(messageErreurAuth(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membresAsync = ref.watch(membresProvider);
    final tontineId = ref.watch(currentTontineIdProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final monMembreId = ref.watch(sessionProvider).value?.profil?.membreId;

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
        title: Text(_modification ? 'Modifier les coordonnées' : membreActuel.nomComplet),
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
                      _EnTeteMembre(membre: membreActuel),
                      const SizedBox(height: AppSpacing.lg),
                      if (membreActuel.whatsapp != null || membreActuel.email != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (membreActuel.whatsapp != null)
                                  _ligneContact(Icons.chat_outlined, membreActuel.whatsapp!),
                                if (membreActuel.whatsapp != null && membreActuel.email != null)
                                  const SizedBox(height: AppSpacing.xs),
                                if (membreActuel.email != null)
                                  _ligneContact(Icons.mail_outline, membreActuel.email!),
                              ],
                            ),
                          ),
                        ),
                      if (membreActuel.codeInvitation != null &&
                          (isAdmin || membreActuel.id == monMembreId)) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _carteCodeInvitation(membreActuel),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Noms détenus', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          if (isAdmin && (tontine == null || noms.length < tontine.nombreDeNoms))
                            TextButton.icon(
                              onPressed: () => _attribuerNoms(tontineId, membreActuel),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Attribuer'),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (nomsDetenus.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              'Aucun nom attribué pour le moment.',
                              style: AppTypography.secondary,
                            ),
                          ),
                        )
                      else
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final detenu in nomsDetenus)
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.canvas,
                                    child: Text(
                                      formatFraction(detenu.fraction),
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.indigo,
                                      ),
                                    ),
                                  ),
                                  title: Text(detenu.nom.libelle),
                                  trailing: isAdmin
                                      ? const Icon(Icons.chevron_right, color: AppColors.slate)
                                      : null,
                                  onTap: !isAdmin
                                      ? null
                                      : () => context.go(
                                          '${AppRouter.membresPath}/noms/${detenu.nom.id}',
                                        ),
                                ),
                            ],
                          ),
                        ),
                      if (tontine != null && nomsDetenus.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _carteMontantDu(tontine, membreActuel, nomsDetenus),
                      ],
                      if (isAdmin) ...[
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
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _ligneContact(IconData icon, String valeur) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.slate),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(valeur, style: AppTypography.body)),
      ],
    );
  }

  Widget _carteCodeInvitation(Membre membre) {
    final inscrit = membre.uid != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  inscrit ? Icons.check_circle_outline : Icons.vpn_key_outlined,
                  size: 18,
                  color: inscrit ? AppColors.success : AppColors.slate,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  inscrit ? 'Membre inscrit' : "Code d'invitation",
                  style: AppTypography.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    membre.codeInvitation!,
                    style: AppTypography.screenTitle.copyWith(letterSpacing: 4),
                  ),
                ),
                IconButton(
                  tooltip: 'Copier le code',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () => _copierCode(membre.codeInvitation!),
                ),
              ],
            ),
            if (!inscrit) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'À transmettre à ${membre.nomComplet} pour qu\'il ou elle rejoigne la tontine.',
                style: AppTypography.secondary,
              ),
            ],
          ],
        ),
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

class _EnTeteMembre extends StatelessWidget {
  const _EnTeteMembre({required this.membre});

  final Membre membre;

  String _initiales(String nom) {
    final mots = nom.trim().split(RegExp(r'\s+'));
    if (mots.isEmpty || mots.first.isEmpty) return '?';
    final premiere = mots.first[0];
    final derniere = mots.length > 1 ? mots.last[0] : '';
    return (premiere + derniere).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.canvas, shape: BoxShape.circle),
          child: Text(
            _initiales(membre.nomComplet),
            style: AppTypography.screenTitle.copyWith(color: AppColors.indigo),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(membre.nomComplet, style: AppTypography.screenTitle),
              if (!membre.actif) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: const Text('Désactivé', style: AppTypography.micro),
                ),
              ] else if (membre.uid == null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: const Text('En attente d\'inscription', style: AppTypography.micro),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeuilleAttribuerNoms extends StatefulWidget {
  const _FeuilleAttribuerNoms({required this.nomComplet});

  final String nomComplet;

  @override
  State<_FeuilleAttribuerNoms> createState() => _FeuilleAttribuerNomsState();
}

class _FeuilleAttribuerNomsState extends State<_FeuilleAttribuerNoms> {
  var _valeur = 1.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Attribuer des noms', style: AppTypography.screenTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Combien de noms supplémentaires pour ${widget.nomComplet} ?',
            style: AppTypography.secondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          NombreDeNomsField(
            value: _valeur,
            minimum: 0.5,
            onChanged: (valeur) => setState(() => _valeur = valeur),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Attribuer',
            variant: AppButtonVariant.accent,
            onPressed: () => Navigator.of(context).pop(_valeur),
          ),
        ],
      ),
    );
  }
}
