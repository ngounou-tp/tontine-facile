/// Conversion entre les lignes Postgres (via PostgREST) et les entités du
/// domaine. Fonctions pures : testées sans serveur.
library;

import '../../domain/entities/adhesion.dart';
import '../../domain/entities/changement.dart';
import '../../domain/entities/cotisation.dart';
import '../../domain/entities/declaration.dart';
import '../../domain/entities/membre.dart';
import '../../domain/entities/nom.dart';
import '../../domain/entities/part.dart';
import '../../domain/entities/tontine.dart';
import '../../domain/entities/tour.dart';
import '../../domain/enums/mode_parts.dart';
import '../../domain/enums/origine_cotisation.dart';
import '../../domain/enums/regle_penalite.dart';
import '../../domain/enums/role_membre.dart';
import '../../domain/enums/statut_cotisation.dart';
import '../../domain/enums/statut_declaration.dart';
import '../../domain/enums/statut_tour.dart';
import '../../domain/enums/type_groupe.dart';
import '../../domain/value_objects/regle_periodicite.dart';

typedef Row = Map<String, dynamic>;

/// `2026-01-10` : les dates métier (échéances, paiements) sont des jours,
/// sans heure ni fuseau — jamais décalées d'un jour autour de minuit UTC.
String encodeDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime decodeDate(Object? value) {
  final texte = value as String;
  final partie = texte.length > 10 ? texte.substring(0, 10) : texte;
  final morceaux = partie.split('-').map(int.parse).toList(growable: false);
  return DateTime(morceaux[0], morceaux[1], morceaux[2]);
}

DateTime decodeTimestamp(Object? value) => DateTime.parse(value as String).toLocal();

int decodeInt(Object? value) => switch (value) {
      final int entier => entier,
      final num nombre => nombre.toInt(),
      final String texte => int.parse(texte),
      _ => throw FormatException('Entier attendu : $value'),
    };

double decodeDouble(Object? value) => switch (value) {
      final num nombre => nombre.toDouble(),
      final String texte => double.parse(texte),
      _ => throw FormatException('Nombre attendu : $value'),
    };

Set<RoleMembre> decodeRoles(Object? value) =>
    {for (final role in (value as List).cast<String>()) RoleMembre.fromId(role)};

// ----------------------------------------------------------------- groupes

/// Ligne `group_members` jointe à son groupe (`groups(name, kind)`).
Adhesion adhesionFromRow(Row row) {
  final groupe = row['groups'] as Row;
  return Adhesion(
    groupeId: row['group_id'] as String,
    membreId: row['id'] as String,
    nomGroupe: groupe['name'] as String,
    type: TypeGroupe.fromId(groupe['kind'] as String),
    roles: decodeRoles(row['roles']),
    actif: row['active'] as bool? ?? true,
  );
}

/// `groups` + `tontine_settings` → [Tontine].
Tontine tontineFromRows(Row groupe, Row reglages) => Tontine(
      id: groupe['id'] as String,
      nom: groupe['name'] as String,
      adminUid: groupe['created_by'] as String,
      montantParNom: decodeInt(reglages['amount_per_name']),
      nombreDeNoms: decodeInt(reglages['names_count']),
      datePremiereEcheance: decodeDate(reglages['first_due_date']),
      periodicite: ReglePeriodicite.fromJson(
        Map<String, dynamic>.from(reglages['periodicity'] as Map),
      ),
      reglePenalite: ReglePenalite.values.byName(reglages['penalty_rule'] as String),
      delaiGraceJours: decodeInt(reglages['grace_days']),
      valeurPenalite: reglages['penalty_value'] == null ? null : decodeInt(reglages['penalty_value']),
      modeParts: ModeParts.fromId(reglages['shares_mode'] as String),
    );

/// Réglages modifiables d'une tontine (`tontine_settings`, `create_tontine`).
Row reglagesToRow(Tontine tontine) => {
      'amount_per_name': tontine.montantParNom,
      'names_count': tontine.nombreDeNoms,
      'first_due_date': encodeDate(tontine.datePremiereEcheance),
      'periodicity': tontine.periodicite.toJson(),
      'penalty_rule': tontine.reglePenalite.name,
      'penalty_value': tontine.valeurPenalite,
      'grace_days': tontine.delaiGraceJours,
      'shares_mode': tontine.modeParts.id,
    };

Membre membreFromRow(Row row) => Membre(
      id: row['id'] as String,
      nomComplet: row['full_name'] as String,
      email: row['email'] as String?,
      whatsapp: row['whatsapp'] as String?,
      uid: row['user_id'] as String?,
      actif: row['active'] as bool? ?? true,
      codeInvitation: row['invitation_code'] as String?,
    );

// ------------------------------------------------------------------- noms

/// Ligne `tontine_names` avec ses parts (`tontine_name_shares(...)`).
Nom nomFromRow(Row row) {
  final parts = [
    for (final part in (row['tontine_name_shares'] as List? ?? const []).cast<Row>())
      Part(membreId: part['member_id'] as String, fraction: decodeDouble(part['fraction'])),
  ]..sort((a, b) => a.membreId.compareTo(b.membreId));
  return Nom(
    id: row['id'] as String,
    position: decodeInt(row['position']),
    libelle: row['label'] as String,
    parts: parts,
  );
}

List<Row> partsToJson(List<Part> parts) => [
      for (final part in parts) {'member_id': part.membreId, 'fraction': part.fraction},
    ];

// ------------------------------------------------------------------ tours

Tour tourFromRow(Row row) => Tour(
      id: row['id'] as String,
      nomId: row['name_id'] as String,
      position: decodeInt(row['position']),
      datePrevue: decodeDate(row['planned_date']),
      statut: StatutTour.values.byName(row['status'] as String),
      montantRemis: row['amount_paid_out'] == null ? null : decodeInt(row['amount_paid_out']),
    );

Row tourToRow(String groupeId, Tour tour) => {
      'id': tour.id,
      'group_id': groupeId,
      'name_id': tour.nomId,
      'position': tour.position,
      'planned_date': encodeDate(tour.datePrevue),
      'status': tour.statut.name,
      'amount_paid_out': tour.montantRemis,
    };

// ------------------------------------------------------------- cotisations

Cotisation cotisationFromRow(Row row) => Cotisation(
      id: row['id'] as String,
      tourId: row['turn_id'] as String,
      nomId: row['name_id'] as String,
      membreId: row['member_id'] as String,
      montantDu: decodeInt(row['amount_due']),
      montantVerse: decodeInt(row['amount_paid']),
      datePaiement: decodeDate(row['payment_date']),
      origine: OrigineCotisation.values.byName(row['origin'] as String),
      statut: StatutCotisation.values.byName(row['status'] as String),
      auteurUid: row['author_id'] as String,
      penalite: decodeInt(row['penalty'] ?? 0),
      motifException: row['exception_reason'] as String?,
      motifRefus: row['rejection_reason'] as String?,
      preuveId: row['proof_id'] as String?,
    );

Row cotisationToRow(String groupeId, Cotisation cotisation) => {
      'id': cotisation.id,
      'group_id': groupeId,
      'turn_id': cotisation.tourId,
      'name_id': cotisation.nomId,
      'member_id': cotisation.membreId,
      'amount_due': cotisation.montantDu,
      'amount_paid': cotisation.montantVerse,
      'payment_date': encodeDate(cotisation.datePaiement),
      'origin': cotisation.origine.name,
      'status': cotisation.statut.name,
      'author_id': cotisation.auteurUid,
      'penalty': cotisation.penalite,
      'exception_reason': cotisation.motifException,
      'rejection_reason': cotisation.motifRefus,
      'proof_id': cotisation.preuveId,
    };

// ------------------------------------------------------------ déclarations

Declaration declarationFromRow(Row row) => Declaration(
      id: row['id'] as String,
      tourId: row['turn_id'] as String,
      nomId: row['name_id'] as String,
      membreId: row['member_id'] as String,
      montantDeclare: decodeInt(row['amount_declared']),
      datePaiement: decodeDate(row['payment_date']),
      preuveId: row['proof_id'] as String,
      statut: StatutDeclaration.values.byName(row['status'] as String),
      motifContestation: row['dispute_reason'] as String?,
      createdAt: decodeTimestamp(row['created_at']),
      updatedAt: row['updated_at'] == null ? null : decodeTimestamp(row['updated_at']),
    );

/// Nouvelle déclaration : toujours « en attente », motif vide (imposé par
/// la RLS) ; l'auteur et la date de création sont fixés par le serveur.
Row declarationToInsertRow(String groupeId, Declaration declaration) => {
      'id': declaration.id,
      'group_id': groupeId,
      'turn_id': declaration.tourId,
      'name_id': declaration.nomId,
      'member_id': declaration.membreId,
      'amount_declared': declaration.montantDeclare,
      'payment_date': encodeDate(declaration.datePaiement),
      'proof_id': declaration.preuveId,
    };

// ------------------------------------------------------------- changements

Changement changementFromRow(Row row) => Changement(
      id: row['id'] as String,
      tourId: row['turn_id'] as String,
      anciennePosition: decodeInt(row['old_position']),
      nouvellePosition: decodeInt(row['new_position']),
      motif: row['reason'] as String,
      auteurUid: row['author_id'] as String,
      createdAt: decodeTimestamp(row['created_at']),
    );
