import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCodec {
  const FirestoreCodec._();

  static String requiredString(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Le champ "$key" doit être une chaîne non vide.');
    }
    return value;
  }

  static String? optionalString(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Le champ "$key" doit être une chaîne.');
    }
    return value;
  }

  static int requiredInt(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is int) return value;
    if (value is num && value == value.toInt()) return value.toInt();
    throw FormatException('Le champ "$key" doit être un entier.');
  }

  static int? optionalInt(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value == value.toInt()) return value.toInt();
    throw FormatException('Le champ "$key" doit être un entier.');
  }

  static double requiredDouble(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is num) return value.toDouble();
    throw FormatException('Le champ "$key" doit être un nombre.');
  }

  static bool requiredBool(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is bool) return value;
    throw FormatException('Le champ "$key" doit être booléen.');
  }

  static DateTime requiredDate(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Le champ "$key" doit être une date Firestore.');
  }

  static DateTime? optionalDate(
    Map<String, dynamic> data,
    String key,
  ) {
    if (data[key] == null) return null;
    return requiredDate(data, key);
  }

  static Timestamp timestamp(DateTime value) => Timestamp.fromDate(value);

  static List<Map<String, dynamic>> mapList(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is! List) {
      throw FormatException('Le champ "$key" doit être une liste.');
    }
    return value.map((item) {
      if (item is! Map) {
        throw FormatException('Les éléments de "$key" doivent être des objets.');
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
