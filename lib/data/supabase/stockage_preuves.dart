import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Fichiers des preuves de paiement (photos compressées), dans un espace
/// privé : seuls les membres du groupe peuvent les lire ou en déposer.
abstract interface class StockagePreuves {
  Future<void> deposer(String chemin, Uint8List octets);
  Future<Uint8List> telecharger(String chemin);
}

class SupabaseStockagePreuves implements StockagePreuves {
  SupabaseStockagePreuves(this._client);

  final SupabaseClient _client;
  static const bucket = 'proofs';

  @override
  Future<void> deposer(String chemin, Uint8List octets) async {
    await _client.storage.from(bucket).uploadBinary(
          chemin,
          octets,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
  }

  @override
  Future<Uint8List> telecharger(String chemin) => _client.storage.from(bucket).download(chemin);
}
