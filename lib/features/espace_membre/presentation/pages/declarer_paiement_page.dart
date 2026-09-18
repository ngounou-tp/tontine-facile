import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../shared/state/flash_message.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/presentation/widgets/auth_form.dart' show messageErreurAuth;
import '../../../cotisations/application/cotisations_providers.dart';
import '../../../cotisations/application/declaration_controller.dart';
import '../../../cotisations/presentation/widgets/preuve_picker.dart';
import '../../../tontine/application/tontine_providers.dart';
import '../../application/espace_membre_providers.dart';

/// Formulaire de déclaration de paiement par un membre : montant (possible
/// partiel), date, et preuve obligatoire. N'affecte aucun total officiel —
/// la déclaration attend la validation de l'administratrice
/// ([DeclarationController]).
class DeclarerPaiementPage extends ConsumerStatefulWidget {
  const DeclarerPaiementPage({required this.nomId, super.key});

  final String nomId;

  @override
  ConsumerState<DeclarerPaiementPage> createState() => _DeclarerPaiementPageState();
}

class _DeclarerPaiementPageState extends ConsumerState<DeclarerPaiementPage> {
  final _montant = TextEditingController();
  var _datePaiement = DateTime.now();
  Uint8List? _preuve;
  String? _erreur;
  var _initialise = false;

  @override
  void dispose() {
    _montant.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _datePaiement,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _datePaiement = date);
  }

  Future<void> _soumettre(String tontineId, SituationNomTourActuel situation, dynamic tour) async {
    final montant = int.tryParse(_montant.text);
    if (montant == null || montant <= 0) {
      setState(() => _erreur = 'Indiquez un montant valide.');
      return;
    }
    if (montant > situation.montantDu - situation.montantVerse) {
      setState(() => _erreur = 'Le montant ne peut pas dépasser le reste à devoir.');
      return;
    }
    if (_preuve == null) {
      setState(() => _erreur = 'Une preuve est obligatoire pour déclarer un paiement.');
      return;
    }
    setState(() => _erreur = null);

    try {
      await ref.read(declarationControllerProvider.notifier).declarerPaiement(
            tontineId: tontineId,
            tour: tour,
            nom: situation.nom,
            membreId: ref.read(membreCourantProvider)!.id,
            montantDeclare: montant,
            datePaiement: _datePaiement,
            preuveBytes: _preuve!,
          );
      if (mounted) {
        ref.read(flashMessageProvider.notifier).set(
              'Déclaration envoyée. En attente de validation par l\'administratrice.',
            );
        context.go(AppRouter.espaceMembrePath);
      }
    } catch (error) {
      if (mounted) setState(() => _erreur = messageErreurAuth(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tour = ref.watch(tourActuelProvider);
    final situations = ref.watch(mesSituationsTourActuelProvider);
    final busy = ref.watch(declarationControllerProvider).isLoading;
    final tontineId = ref.watch(currentTontineIdProvider);

    SituationNomTourActuel? situation;
    for (final candidate in situations) {
      if (candidate.nom.id == widget.nomId) {
        situation = candidate;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => context.go(AppRouter.espaceMembrePath),
        ),
        title: const Text("J'ai payé"),
      ),
      body: tour == null || situation == null || tontineId == null
          ? (situations.isEmpty && tour == null
              ? const LoadingView()
              : const ErrorView(message: 'Ce nom ne peut plus être déclaré pour le tour en cours.'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Builder(
                    builder: (context) {
                      if (!_initialise) {
                        _montant.text = '${situation!.montantDu - situation.montantVerse}';
                        _initialise = true;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(situation!.nom.libelle, style: AppTypography.screenTitle),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Reste à devoir : ${situation.montantDu - situation.montantVerse} FCFA',
                            style: AppTypography.secondary,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Text('Montant versé', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _montant,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(suffixText: 'FCFA', errorText: _erreur),
                            onChanged: (_) {
                              if (_erreur != null) setState(() => _erreur = null);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text('Date du paiement', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                            onTap: _choisirDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_datePaiement.day.toString().padLeft(2, '0')}/'
                                    '${_datePaiement.month.toString().padLeft(2, '0')}/'
                                    '${_datePaiement.year}',
                                    style: AppTypography.body,
                                  ),
                                  const Icon(Icons.calendar_month_outlined, color: AppColors.slate),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PreuvePicker(
                            value: _preuve,
                            obligatoire: true,
                            onChanged: (valeur) => setState(() => _preuve = valeur),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: 'Envoyer la déclaration',
                            variant: AppButtonVariant.accent,
                            busy: busy,
                            onPressed: busy ? null : () => _soumettre(tontineId, situation!, tour),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
