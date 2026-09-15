import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/images/logo_placeholder.png', width: 88, height: 88),
        const SizedBox(height: AppSpacing.md),
        const Text('TontineFacile', style: AppTypography.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        const Text('Le registre de votre tontine, toujours à jour', textAlign: TextAlign.center, style: AppTypography.secondary),
      ],
    );
  }
}
