import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tontinefacile/domain/entities/membre.dart';
import 'package:tontinefacile/domain/entities/part.dart';
import 'package:tontinefacile/features/membres/presentation/widgets/parts_editor.dart';

void main() {
  const membres = [
    Membre(id: 'm-1', nomComplet: 'Rose Domche'),
    Membre(id: 'm-2', nomComplet: 'Alice Pouth'),
  ];

  Future<List<Part>> pump(WidgetTester tester, {List<Part> initial = const []}) async {
    List<Part> emis = initial;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartsEditor(
            membres: membres,
            initialParts: initial,
            onChanged: (parts) => emis = parts,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return emis;
  }

  group('formatFraction', () {
    test('affiche "Part entière" pour 1', () {
      expect(formatFraction(1), 'Part entière');
    });

    test('affiche les glyphes usuels', () {
      expect(formatFraction(0.5), '½');
      expect(formatFraction(1 / 3), '⅓');
      expect(formatFraction(0.25), '¼');
      expect(formatFraction(0.75), '¾');
    });

    test('repli en pourcentage pour une fraction non usuelle', () {
      expect(formatFraction(0.3), '30 %');
    });
  });

  testWidgets('affiche un membre à cocher par membre fourni', (tester) async {
    await pump(tester);

    expect(find.text('Rose Domche'), findsOneWidget);
    expect(find.text('Alice Pouth'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });

  testWidgets('sélectionner un seul membre lui attribue 100 %', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartsEditor(membres: membres, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text('Total : 100 %'), findsOneWidget);
    expect(find.text('Part entière'), findsOneWidget);
  });

  testWidgets('sélectionner deux membres répartit également 50 / 50', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartsEditor(membres: membres, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Total : 100 %'), findsOneWidget);
    expect(find.text('½'), findsNWidgets(2));
  });

  testWidgets('une répartition incomplète affiche une somme invalide', (tester) async {
    List<Part> emis = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartsEditor(membres: membres, onChanged: (parts) => emis = parts),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.pumpAndSettle();

    expect(find.text('Total : 80 %'), findsOneWidget);
    expect(emis.fold<double>(0, (s, p) => s + p.fraction), closeTo(0.8, 0.001));
  });

  testWidgets('initialParts pré-sélectionne les détenteurs existants', (tester) async {
    await pump(
      tester,
      initial: const [
        Part(membreId: 'm-1', fraction: 0.5),
        Part(membreId: 'm-2', fraction: 0.5),
      ],
    );

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(checkboxes[0].value, isTrue);
    expect(checkboxes[1].value, isTrue);
    expect(find.text('Total : 100 %'), findsOneWidget);
  });
}
