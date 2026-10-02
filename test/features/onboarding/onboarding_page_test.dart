import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tontinefacile/features/onboarding/application/onboarding_provider.dart';
import 'package:tontinefacile/features/onboarding/presentation/pages/onboarding_page.dart';

void _tailleTelephone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late SharedPreferences preferences;

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/decouvrir',
      routes: [
        GoRoute(path: '/decouvrir', builder: (_, _) => const OnboardingPage()),
        GoRoute(path: '/connexion', builder: (_, _) => const Text('CONNEXION_PAGE')),
        GoRoute(path: '/rejoindre', builder: (_, _) => const Text('REJOINDRE_PAGE')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  testWidgets('parcourt les trois étapes puis mène à la connexion, une seule fois', (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('sans cahier'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('suivi en direct'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('vous validez'), findsOneWidget);
    expect(find.text('Validée'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('CONNEXION_PAGE'), findsOneWidget);
    expect(preferences.getBool('onboarding_vu_v1'), isTrue);
  });

  testWidgets('« Passer » termine immédiatement l’onboarding', (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('CONNEXION_PAGE'), findsOneWidget);
    expect(preferences.getBool('onboarding_vu_v1'), isTrue);
  });

  testWidgets("le code d'invitation mène directement à l'écran pour rejoindre", (tester) async {
    _tailleTelephone(tester);
    await pumpPage(tester);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();

    await tester.tap(find.text("J'ai reçu un code d'invitation"));
    await tester.pumpAndSettle();
    expect(find.text('REJOINDRE_PAGE'), findsOneWidget);
  });
}
