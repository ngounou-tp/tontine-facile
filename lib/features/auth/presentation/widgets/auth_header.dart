import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/tontine_logo.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TontineLogo(size: 88, activeIndex: 0),
        const SizedBox(height: AppSpacing.md),
        const Text('TontineFacile', style: AppTypography.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        const Text('Le registre de votre tontine, toujours à jour', textAlign: TextAlign.center, style: AppTypography.secondary),
      ],
    );
  }
}
