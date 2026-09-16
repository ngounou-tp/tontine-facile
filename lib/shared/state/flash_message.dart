import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Message à afficher en toast (SnackBar) sur le prochain écran atteint par
/// navigation — par exemple une confirmation de création après
/// redirection. Un écran qui veut le consommer regarde
/// [FlashMessageListener].
final flashMessageProvider = NotifierProvider<FlashMessageNotifier, String?>(
  FlashMessageNotifier.new,
);

class FlashMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String message) => state = message;

  void clear() => state = null;
}

/// Affiche, une seule fois, le message porté par [flashMessageProvider] en
/// SnackBar dès que l'écran englobant est construit, puis le vide.
///
/// À placer en tête du `build()` d'un écran de destination (ex. la liste des
/// membres après création de la tontine) : `FlashMessageListener.attach(ref,
/// context);` avant de construire le reste de l'arbre.
abstract final class FlashMessageListener {
  static void attach(WidgetRef ref, BuildContext context) {
    ref.listen<String?>(flashMessageProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
        }
      });
      ref.read(flashMessageProvider.notifier).clear();
    });
  }
}
