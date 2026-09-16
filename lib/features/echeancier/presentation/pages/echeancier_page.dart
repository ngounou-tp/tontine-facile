import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/coming_soon_view.dart';

/// Onglet Échéancier : programme des tours, à venir (réorganisation par
/// glisser-déposer, suivi des paiements par tour).
class EcheancierPage extends StatelessWidget {
  const EcheancierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedNavIndex: 2,
      appBar: AppBar(title: const Text('Échéancier')),
      body: const ComingSoonView(
        title: 'Échéancier',
        message: "Le suivi détaillé des tours arrive bientôt. L'échéancier généré depuis "
            'Membres reste actif en coulisses.',
        icon: Icons.calendar_month_outlined,
      ),
    );
  }
}
