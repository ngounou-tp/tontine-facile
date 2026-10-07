import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/tontine_logo.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/l10n.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TontineLogo(size: 88, activeIndex: 0),
        const SizedBox(height: AppSpacing.md),
        const Text(AppConstants.appName, style: AppTypography.pageTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(context.l10n.authTagline, textAlign: TextAlign.center, style: AppTypography.secondary),
      ],
    );
  }
}
