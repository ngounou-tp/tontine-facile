import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../domain/entities/membre.dart';
import '../../../../domain/entities/part.dart';

const _glyphsParDenominateur = {
  2: {1: '½'},
  3: {1: '⅓', 2: '⅔'},
  4: {1: '¼', 3: '¾'},
  5: {1: '⅕', 2: '⅖', 3: '⅗', 4: '⅘'},
  6: {1: '⅙', 5: '⅚'},
  8: {1: '⅛', 3: '⅜', 5: '⅝', 7: '⅞'},
};

/// Formate une fraction pour affichage, en phrase comme en badge : « 1 »,
/// un glyphe usuel (« ½ », « ⅓ »…) ou un pourcentage arrondi en dernier
/// recours. Volontairement court partout — « Part entière » débordait des
/// badges circulaires et des colonnes étroites (éditeur de parts).
String formatFraction(double fraction) {
  if ((fraction - 1).abs() < 1e-6) return '1';
  return _glyphe(fraction);
}

String _glyphe(double fraction) {
  for (final entry in _glyphsParDenominateur.entries) {
    final numerateur = (fraction * entry.key).round();
    if ((numerateur / entry.key - fraction).abs() < 1e-6) {
      final glyphe = entry.value[numerateur];
      if (glyphe != null) return glyphe;
    }
  }
  return '${(fraction * 100).round()} %';
}

/// Éditeur des détenteurs de part d'un nom : sélection des membres actifs
/// puis répartition de leur fraction (égale par défaut, ajustable
/// manuellement en pourcentage). Émet la liste de [Part] courante à chaque
/// changement, même si la somme n'est pas encore égale à 1 — la validation
/// finale (via `ValidationParts`) reste à la charge de l'écran appelant, qui
/// peut utiliser [PartsEditor.sommeFractions] pour désactiver son bouton
/// d'enregistrement tant que la répartition n'est pas complète.
class PartsEditor extends StatefulWidget {
  const PartsEditor({
    required this.membres,
    required this.onChanged,
    this.initialParts = const [],
    super.key,
  });

  final List<Membre> membres;
  final List<Part> initialParts;
  final ValueChanged<List<Part>> onChanged;

  static double sommeFractions(List<Part> parts) =>
      parts.fold(0, (total, part) => total + part.fraction);

  @override
  State<PartsEditor> createState() => _PartsEditorState();
}

class _PartsEditorState extends State<PartsEditor> {
  late Set<String> _selectionnes;
  late Map<String, TextEditingController> _pourcentages;

  @override
  void initState() {
    super.initState();
    _selectionnes = widget.initialParts.map((p) => p.membreId).toSet();
    _pourcentages = {
      for (final part in widget.initialParts)
        part.membreId: TextEditingController(text: '${(part.fraction * 100).round()}'),
    };
  }

  @override
  void dispose() {
    for (final controller in _pourcentages.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _basculer(String membreId) {
    setState(() {
      if (_selectionnes.contains(membreId)) {
        _selectionnes.remove(membreId);
        _pourcentages.remove(membreId)?.dispose();
      } else {
        _selectionnes.add(membreId);
      }
      _repartirEgalement();
    });
    _emettre();
  }

  void _repartirEgalement() {
    if (_selectionnes.isEmpty) return;
    final part = (100 / _selectionnes.length).round();
    for (final id in _selectionnes) {
      _pourcentages.putIfAbsent(id, () => TextEditingController()).text = '$part';
    }
  }

  void _emettre() {
    final parts = [
      for (final id in _selectionnes)
        Part(
          membreId: id,
          fraction: (int.tryParse(_pourcentages[id]?.text ?? '') ?? 0) / 100,
        ),
    ];
    widget.onChanged(parts);
  }

  @override
  Widget build(BuildContext context) {
    final somme = _selectionnes.fold<double>(
      0,
      (total, id) => total + (int.tryParse(_pourcentages[id]?.text ?? '') ?? 0) / 100,
    );
    final sommeValide = (somme - 1).abs() < 0.005;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Détenteurs de part', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: _selectionnes.length > 1
                  ? () {
                      setState(_repartirEgalement);
                      _emettre();
                    }
                  : null,
              child: const Text('Répartir également'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final membre in widget.membres) _ligneMembre(membre),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              sommeValide ? Icons.check_circle : Icons.error_outline,
              color: sommeValide ? AppColors.success : AppColors.danger,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Total : ${(somme * 100).round()} %',
              style: AppTypography.secondary.copyWith(
                color: sommeValide ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ligneMembre(Membre membre) {
    final selectionne = _selectionnes.contains(membre.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(value: selectionne, onChanged: (_) => _basculer(membre.id)),
          Expanded(
            child: Text(membre.nomComplet, style: AppTypography.body),
          ),
          if (selectionne) ...[
            SizedBox(
              width: 72,
              child: TextFormField(
                controller: _pourcentages[membre.id],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(suffixText: ' %', isDense: true),
                onChanged: (_) {
                  setState(() {});
                  _emettre();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 40,
              child: Text(
                formatFraction((int.tryParse(_pourcentages[membre.id]?.text ?? '') ?? 0) / 100),
                style: AppTypography.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
