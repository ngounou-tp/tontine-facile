import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../state/flash_message.dart';
import '../widgets/coming_soon_view.dart';

/// Destination temporaire pour les parcours dont l'écran métier n'est pas
/// encore intégré. Chaque route reste navigable et sécurisée dès maintenant.
///
/// Réservé aux destinations qui ne sont pas un onglet de la barre de
/// navigation principale (celles-ci utilisent [AppScaffold] pour rester
/// cohérentes avec les autres sections) — la flèche de retour ramène donc
/// systématiquement à l'accueil plutôt qu'à l'onglet précédent.
class RoutePlaceholderPage extends ConsumerWidget {
  const RoutePlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlashMessageListener.attach(ref, context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () => context.go(AppRouter.accueilPath),
        ),
        title: Text(title),
      ),
      body: ComingSoonView(title: title),
    );
  }
}
