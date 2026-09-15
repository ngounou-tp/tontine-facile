import 'package:flutter/material.dart';

/// Destination temporaire pour les parcours dont l'écran métier n'est pas
/// encore intégré. Chaque route reste navigable et sécurisée dès maintenant.
class RoutePlaceholderPage extends StatelessWidget {
  const RoutePlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
