import 'adhesion.dart';
import 'app_user.dart';
import 'profil.dart';

/// Session applicative : l'utilisateur authentifié, tous les groupes
/// auxquels il appartient, et le groupe actuellement affiché.
///
/// [profil] est `null` tant que le compte n'appartient à aucun groupe
/// (création ou adhésion à faire).
class Session {
  final AppUser utilisateur;
  final List<Adhesion> adhesions;
  final Profil? profil;

  const Session({
    required this.utilisateur,
    this.adhesions = const [],
    this.profil,
  });
}
