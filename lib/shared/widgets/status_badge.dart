import 'package:flutter/material.dart';

import 'app_pill.dart';
import '../../l10n/l10n.dart';

enum StatusBadgeType { paid, late, partial, exception, toCollect }

/// Statut de paiement standard, rendu avec la pastille commune [AppPill].
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.type});

  final StatusBadgeType type;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (type) {
      StatusBadgeType.paid => (context.l10n.statusPaid, AppTone.success),
      StatusBadgeType.late => (context.l10n.statusLate, AppTone.danger),
      StatusBadgeType.partial => (context.l10n.statusPartial, AppTone.warning),
      StatusBadgeType.exception => (context.l10n.statusException, AppTone.warning),
      StatusBadgeType.toCollect => (context.l10n.statusToCollect, AppTone.neutral),
    };
    return AppPill(label: label, tone: tone);
  }
}
