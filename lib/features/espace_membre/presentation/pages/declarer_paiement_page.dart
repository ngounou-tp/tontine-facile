import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/amount_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
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
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/l10n.dart';

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

  /// Erreur liée au montant : affichée sous le champ montant.
  String? _erreur;

  /// Erreur liée à la preuve ou à l'envoi : affichée près du bouton, et non
  /// sous le montant (qui laisserait croire que c'est lui le problème).
  String? _erreurEnvoi;
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
      setState(() => _erreur = context.l10n.declareInvalidAmount);
      return;
    }
    if (montant > situation.montantDu - situation.montantVerse) {
      setState(() => _erreur = context.l10n.declareAmountExceedsRemaining);
      return;
    }
    if (_preuve == null) {
      setState(() {
        _erreur = null;
        _erreurEnvoi = context.l10n.declareProofRequired;
      });
      return;
    }
    setState(() {
      _erreur = null;
      _erreurEnvoi = null;
    });

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
        HapticFeedback.mediumImpact();
        ref.read(flashMessageProvider.notifier).set(
              context.l10n.declareSent,
            );
        context.go(AppRouter.espaceMembrePath);
      }
    } catch (error) {
      if (mounted) setState(() => _erreurEnvoi = messageErreurAuth(error));
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
          tooltip: context.l10n.commonBack,
          onPressed: () => context.go(AppRouter.espaceMembrePath),
        ),
        title: Text(context.l10n.declareTitle),
      ),
      body: tour == null || situation == null || tontineId == null
          ? (situations.isEmpty && tour == null
              ? const LoadingView()
              : ErrorView(message: context.l10n.declareNotAllowed))
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
                            context.l10n.declareRemaining(formatAmount(situation.montantDu - situation.montantVerse)),
                            style: AppTypography.secondary,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(context.l10n.contribAmountPaid, style: AppTypography.bodyStrong),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _montant,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: AppTypography.amountXl.copyWith(fontSize: 28),
                            decoration: InputDecoration(
                              suffixText: AppConstants.currency,
                              suffixStyle: AppTypography.bodyStrong.copyWith(color: AppColors.slate),
                              errorText: _erreur,
                            ),
                            onChanged: (_) {
                              if (_erreur != null) setState(() => _erreur = null);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(context.l10n.contribPaymentDate, style: AppTypography.bodyStrong),
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
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.indigo),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: Text(formatDate(_datePaiement), style: AppTypography.body)),
                                  Text(formatEcheanceRelative(_datePaiement), style: AppTypography.secondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PreuvePicker(
                            value: _preuve,
                            obligatoire: true,
                            onChanged: (valeur) => setState(() {
                              _preuve = valeur;
                              if (valeur != null) _erreurEnvoi = null;
                            }),
                          ),
                          AnimatedSize(
                            duration: AppMotion.medium,
                            curve: AppMotion.easeOut,
                            child: _erreurEnvoi == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            _erreurEnvoi!,
                                            style: AppTypography.secondary.copyWith(color: AppColors.danger),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: context.l10n.declareSubmit,
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
