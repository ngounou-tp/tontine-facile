import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales, chargées une fois dans `main()` avant `runApp` puis
/// injectées par override : le routeur peut ainsi lire l'état de
/// l'onboarding de façon synchrone, sans écran de chargement intermédiaire.
///
/// `null` hors de l'app réelle (tests, outils) : l'onboarding est alors
/// considéré comme déjà vu et n'interfère avec aucun parcours.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// L'utilisateur a-t-il déjà parcouru (ou passé) l'onboarding ?
final onboardingVuProvider = NotifierProvider<OnboardingVuNotifier, bool>(
  OnboardingVuNotifier.new,
);

class OnboardingVuNotifier extends Notifier<bool> {
  static const _cle = 'onboarding_vu_v1';

  @override
  bool build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    if (preferences == null) return true;
    return preferences.getBool(_cle) ?? false;
  }

  /// Marque l'onboarding comme vu, définitivement pour cet appareil.
  Future<void> terminer() async {
    state = true;
    await ref.read(sharedPreferencesProvider)?.setBool(_cle, true);
  }
}
