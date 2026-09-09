import '../enums/jour_semaine.dart';
import '../enums/occurrence_mensuelle.dart';

sealed class ReglePeriodicite {
  const ReglePeriodicite();

  Map<String, dynamic> toJson();

  factory ReglePeriodicite.tousLesNJours(int jours) =
      RegleTousLesNJours;

  factory ReglePeriodicite.chaqueSemaine(
    JourSemaine jour,
  ) = RegleChaqueSemaine;

  factory ReglePeriodicite.toutesLesDeuxSemaines(
    JourSemaine jour,
  ) = RegleToutesLesDeuxSemaines;

  factory ReglePeriodicite.chaqueMoisJourFixe(
    int jour,
  ) = RegleChaqueMoisJourFixe;

  factory ReglePeriodicite.chaqueMoisSemaine(
    OccurrenceMensuelle occurrence,
    JourSemaine jour,
  ) = RegleChaqueMoisSemaine;

  static ReglePeriodicite fromJson(
    Map<String, dynamic> json,
  ) {
    final type = json['type'];

    if (type is! String) {
      throw const FormatException(
        'Le type de périodicité est obligatoire.',
      );
    }

    return switch (type) {
      'tousLesNJours' =>
        RegleTousLesNJours(
          _readInt(json, 'jours'),
        ),

      'chaqueSemaine' =>
        RegleChaqueSemaine(
          JourSemaine.fromInt(
            _readInt(json, 'jourDeLaSemaine'),
          ),
        ),

      'toutesLesDeuxSemaines' =>
        RegleToutesLesDeuxSemaines(
          JourSemaine.fromInt(
            _readInt(json, 'jourDeLaSemaine'),
          ),
        ),

      'chaqueMoisJourFixe' =>
        RegleChaqueMoisJourFixe(
          _readInt(json, 'jour'),
        ),

      'chaqueMoisSemaine' =>
        RegleChaqueMoisSemaine(
          OccurrenceMensuelle.fromInt(
            _readInt(json, 'occurrence'),
          ),
          JourSemaine.fromInt(
            _readInt(json, 'jourDeLaSemaine'),
          ),
        ),

      _ => throw UnsupportedError(
          'Type de périodicité inconnu : $type',
        ),
    };
  }
}

class RegleTousLesNJours extends ReglePeriodicite {
  const RegleTousLesNJours(this.jours) : assert(jours > 0);

  final int jours;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'tousLesNJours',
      'jours': jours,
    };
  }
}


class RegleChaqueSemaine extends ReglePeriodicite {
  const RegleChaqueSemaine(this.jour);

  final JourSemaine jour;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'chaqueSemaine',
      'jourDeLaSemaine': jour.value,
    };
  }
}


class RegleToutesLesDeuxSemaines extends ReglePeriodicite {
  const RegleToutesLesDeuxSemaines(this.jour);

  final JourSemaine jour;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'toutesLesDeuxSemaines',
      'jourDeLaSemaine': jour.value,
    };
  }
}


class RegleChaqueMoisJourFixe extends ReglePeriodicite {
  const RegleChaqueMoisJourFixe(this.jour);

  final int jour;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'chaqueMoisJourFixe',
      'jour': jour,
    };
  }
}


class RegleChaqueMoisSemaine extends ReglePeriodicite {
  const RegleChaqueMoisSemaine(
    this.occurrence,
    this.jour,
  );

  final OccurrenceMensuelle occurrence;
  final JourSemaine jour;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'chaqueMoisSemaine',
      'occurrence': occurrence.value,
      'jourDeLaSemaine': jour.value,
    };
  }
}


int _readInt(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];

  if (value is! int) {
    throw FormatException(
      'Le champ "$key" doit être un entier.',
    );
  }

  return value;
}