import 'package:flutter/material.dart';

import 'app_pill.dart';

enum StatusBadgeType { paid, late, partial, exception, toCollect }

/// Statut de paiement standard, rendu avec la pastille commune [AppPill].
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.type});

  final StatusBadgeType type;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (type) {
      StatusBadgeType.paid => ('Payé', AppTone.success),
      StatusBadgeType.late => ('En retard', AppTone.danger),
      StatusBadgeType.partial => ('Partiel', AppTone.warning),
      StatusBadgeType.exception => ('Exception', AppTone.warning),
      StatusBadgeType.toCollect => ('À encaisser', AppTone.neutral),
    };
    return AppPill(label: label, tone: tone);
  }
}
