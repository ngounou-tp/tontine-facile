import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AmountField extends StatelessWidget {
  const AmountField({super.key, this.controller, this.errorText, this.enabled = true, this.onChanged});

  final TextEditingController? controller;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      style: AppTypography.amount,
      decoration: InputDecoration(
        labelText: 'Montant de la cotisation',
        hintText: '25 000 FCFA',
        errorText: errorText,
        suffixText: 'FCFA',
      ),
    );
  }
}