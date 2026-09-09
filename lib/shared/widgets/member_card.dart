import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'status_badge.dart';

enum MemberStatus { paid, late, partial, toCollect }

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.initials,
    required this.name,
    required this.amount,
    required this.detail,
    required this.status,
    this.footer,
    this.onPayment,
    this.onMore,
  });

  final String initials;
  final String name;
  final String amount;
  final String detail;
  final MemberStatus status;
  final String? footer;
  final VoidCallback? onPayment;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Initials(value: initials),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)),
                          const SizedBox(width: AppSpacing.sm),
                          Text(amount, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Sora')),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(child: Text(detail, style: Theme.of(context).textTheme.bodyMedium)),
                          StatusBadge(type: _badgeType(status)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onPayment != null || onMore != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Row(
                  children: [
                    if (onPayment != null)
                      Expanded(
                        child: OutlinedButton(onPressed: onPayment, child: const Text('Noter un paiement')),
                      ),
                    if (onPayment != null && onMore != null) const SizedBox(width: AppSpacing.xs),
                    if (onMore != null)
                      IconButton(onPressed: onMore, tooltip: 'Plus d’options', icon: const Icon(Icons.more_horiz)),
                  ],
                ),
              ),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: Alignment.centerLeft, child: Text(footer!, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ],
        ),
      ),
    );
  }

  StatusBadgeType _badgeType(MemberStatus value) {
    return switch (value) {
      MemberStatus.paid => StatusBadgeType.paid,
      MemberStatus.late => StatusBadgeType.late,
      MemberStatus.partial => StatusBadgeType.partial,
      MemberStatus.toCollect => StatusBadgeType.toCollect,
    };
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.canvas, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppSpacing.sm)),
      child: Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Sora')),
    );
  }
}

