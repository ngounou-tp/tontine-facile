import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/app_button.dart';
import 'nombre_de_noms_field.dart';

/// Valeur soumise par [MembreForm] : nom complet, au moins un moyen de
/// contact (email ou WhatsApp), et le nombre de noms attribués — un
/// multiple de `0.5` (voir [MembreForm.afficherNombreDeNoms]).
typedef MembreFormValue = ({
  String nomComplet,
  String? email,
  String? whatsapp,
  double nombreDeNoms,
});

/// Formulaire d'identité et de contact d'un membre, réutilisé pour l'ajout
/// et la modification. Auto-validé : exige un nom d'au moins 2 caractères et
/// au moins un moyen de contact (email ou WhatsApp).
///
/// [afficherNombreDeNoms] n'a de sens qu'à la création : un membre déjà
/// enregistré gère ses noms depuis « Membres » plutôt qu'en modifiant sa
/// fiche.
class MembreForm extends StatefulWidget {
  const MembreForm({
    required this.submitLabel,
    required this.onSubmit,
    this.nomComplet = '',
    this.email = '',
    this.whatsapp = '',
    this.busy = false,
    this.afficherNombreDeNoms = false,
    this.nombreDeNomsInitial = 1,
    super.key,
  });

  final String nomComplet;
  final String email;
  final String whatsapp;
  final String submitLabel;
  final bool busy;
  final bool afficherNombreDeNoms;
  final double nombreDeNomsInitial;
  final ValueChanged<MembreFormValue> onSubmit;

  @override
  State<MembreForm> createState() => _MembreFormState();
}

class _MembreFormState extends State<MembreForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomComplet;
  late final TextEditingController _email;
  late final TextEditingController _whatsapp;
  late double _nombreDeNoms;

  @override
  void initState() {
    super.initState();
    _nomComplet = TextEditingController(text: widget.nomComplet);
    _email = TextEditingController(text: widget.email);
    _whatsapp = TextEditingController(text: widget.whatsapp);
    _nombreDeNoms = widget.nombreDeNomsInitial;
  }

  @override
  void dispose() {
    _nomComplet.dispose();
    _email.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  String? _erreurContact() {
    if (_email.text.trim().isEmpty && _whatsapp.text.trim().isEmpty) {
      return 'Indiquez au moins un email ou un numéro WhatsApp.';
    }
    return null;
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit((
      nomComplet: _nomComplet.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
      nombreDeNoms: _nombreDeNoms,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _nomComplet,
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Le nom doit contenir au moins 2 caractères.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Numéro WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _whatsapp,
            keyboardType: TextInputType.phone,
            validator: (_) => _erreurContact(),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (_) => _erreurContact(),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Au moins un des deux moyens de contact est requis.',
            style: AppTypography.secondary,
          ),
          if (widget.afficherNombreDeNoms) ...[
            const SizedBox(height: AppSpacing.md),
            const Text('Nombre de noms', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            NombreDeNomsField(
              value: _nombreDeNoms,
              onChanged: (valeur) => setState(() => _nombreDeNoms = valeur),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Un nom peut être partagé en demies entre deux membres ; le nom entier '
              'lui appartient exclusivement.',
              style: AppTypography.secondary,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.submitLabel,
            variant: AppButtonVariant.accent,
            busy: widget.busy,
            onPressed: widget.busy ? null : _soumettre,
          ),
        ],
      ),
    );
  }
}
