import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/tontine.dart';
import '../../../../domain/enums/mode_parts.dart';
import '../../../../domain/enums/regle_penalite.dart';
import '../../../../domain/rules/contribution_calculator.dart';
import '../../../../domain/value_objects/regle_periodicite.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_navigation.dart';
import '../../../../shared/widgets/member_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final tontines = [
    _HomeTontine(
      tontine: Tontine(
        id: 'cercle-des-amis',
        nom: 'Cercle des amis',
        adminUid: 'admin-demo',
        montantParNom: 25000,
        datePremiereEcheance: DateTime(2024, 3, 14),
        periodicite: ReglePeriodicite.chaqueMoisJourFixe(14),
        reglePenalite: ReglePenalite.aucune,
        delaiGraceJours: 0,
        valeurPenalite: null,
        modeParts: ModeParts.montantFixe,
        codeInvitation: 'AMIS01',
      ),
      memberCount: 12,
      nextDueDate: 'Jeudi 14 mars',
    ),
    _HomeTontine(
      tontine: Tontine(
        id: 'famille-elargie',
        nom: 'Famille élargie',
        adminUid: 'admin-demo',
        montantParNom: 15000,
        datePremiereEcheance: DateTime(2024, 3, 18),
        periodicite: ReglePeriodicite.chaqueMoisJourFixe(18),
        reglePenalite: ReglePenalite.aucune,
        delaiGraceJours: 0,
        valeurPenalite: null,
        modeParts: ModeParts.montantFixe,
        codeInvitation: 'FAM001',
      ),
      memberCount: 8,
      nextDueDate: 'Lundi 18 mars',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final calculator = const ContributionCalculator();
    final total = tontines.fold<double>(
      0,
      (sum, item) => sum + calculator.totalPot(
        contribution: item.tontine.montantParNom.toDouble(),
        memberCount: item.memberCount,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('TontineFacile'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          IconButton(onPressed: () {}, tooltip: 'Notifications', icon: const Icon(Icons.notifications_none_rounded)),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        children: [
          Text('Bonjour, Aïcha', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Voici le résumé de vos cercles.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          _SummaryCard(total: total),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mes tontines', style: Theme.of(context).textTheme.titleLarge),
              AppButton(label: 'Créer', icon: Icons.add, variant: AppButtonVariant.tertiary, onPressed: () {}),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tontines.map((tontine) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _TontineCard(tontine: tontine))),
          const SizedBox(height: AppSpacing.lg),
          Text('Suivi des membres', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const MemberCard(
            initials: 'MN',
            name: 'Marie Ngo Bakoto',
            amount: '25 000 FCFA',
            detail: 'N° 04 · tour 3 sur 12',
            status: MemberStatus.paid,
            footer: 'Encaissé par Adèle · 12 mars, 10 h 24',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      bottomNavigationBar: AppNavigation(selectedIndex: 0, onSelected: (_) {}),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.ink,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total à distribuer', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.accent)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${total.toStringAsFixed(0)} FCFA', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.surface)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('sur 2 cercles actifs', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.surface.withValues(alpha: 0.7))),
                ],
              ),
            ),
            const CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.savings_outlined, color: AppColors.ink, size: 28)),
          ],
        ),
      ),
    );
  }
}

class _TontineCard extends StatelessWidget {
  const _TontineCard({required this.tontine});

  final _HomeTontine tontine;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.groups_rounded, color: AppColors.ink)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tontine.tontine.nom, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${tontine.memberCount} membres - ${tontine.tontine.montantParNom} FCFA / mois', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Prochaine collecte : ${tontine.nextDueDate}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.success)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.slate),
          ],
        ),
      ),
    );
  }
}

class _HomeTontine {
  final Tontine tontine;
  final int memberCount;
  final String nextDueDate;

  const _HomeTontine({
    required this.tontine,
    required this.memberCount,
    required this.nextDueDate,
  });
}