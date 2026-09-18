import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';

/// Taille maximale d'une preuve compressée, en octets (150 Ko — voir
/// `Preuve`, stockée encodée en base64 dans Firestore).
const preuveTailleMaxOctets = 150 * 1024;

/// Sélecteur de preuve de paiement (photo) : capture ou choix depuis la
/// galerie, puis compression sous [preuveTailleMaxOctets] avant d'exposer
/// les octets via [onChanged]. Entièrement contrôlé — le formulaire
/// appelant reste responsable de l'encodage/l'enregistrement final
/// (`Preuve`).
class PreuvePicker extends StatefulWidget {
  const PreuvePicker({
    required this.onChanged,
    this.value,
    this.obligatoire = false,
    super.key,
  });

  final Uint8List? value;
  final ValueChanged<Uint8List?> onChanged;

  /// Affiche « Preuve obligatoire » plutôt que « Preuve (optionnelle) ».
  final bool obligatoire;

  @override
  State<PreuvePicker> createState() => _PreuvePickerState();
}

class _PreuvePickerState extends State<PreuvePicker> {
  var _enCours = false;
  String? _erreur;

  Future<void> _choisir(ImageSource source) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final fichier = await ImagePicker().pickImage(source: source, imageQuality: 90);
      if (fichier == null) {
        setState(() => _enCours = false);
        return;
      }
      final octets = await _compresser(await fichier.readAsBytes());
      widget.onChanged(octets);
    } catch (_) {
      setState(() => _erreur = "Impossible de récupérer l'image. Réessayez.");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// Réduit la qualité JPEG par paliers jusqu'à passer sous
  /// [preuveTailleMaxOctets] ; conserve le meilleur résultat obtenu si la
  /// limite reste hors d'atteinte (photo intrinsèquement très détaillée).
  Future<Uint8List> _compresser(Uint8List original) async {
    var meilleur = original;
    for (final qualite in [85, 65, 45, 30, 15]) {
      final compresse = await FlutterImageCompress.compressWithList(
        original,
        quality: qualite,
        minWidth: 1024,
        minHeight: 1024,
      );
      if (compresse.lengthInBytes < meilleur.lengthInBytes) meilleur = compresse;
      if (compresse.lengthInBytes <= preuveTailleMaxOctets) return compresse;
    }
    return meilleur;
  }

  Future<void> _ouvrirChoix() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _choisir(source);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.obligatoire ? 'Preuve (obligatoire)' : 'Preuve (optionnelle)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (widget.value != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            child: Stack(
              children: [
                Image.memory(widget.value!, height: 160, width: double.infinity, fit: BoxFit.cover),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    radius: 16,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.close, color: AppColors.danger),
                      tooltip: 'Retirer la preuve',
                      onPressed: () => widget.onChanged(null),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _enCours ? null : _ouvrirChoix,
            icon: _enCours
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined),
            label: Text(_enCours ? 'Compression en cours…' : 'Ajouter une preuve'),
          ),
        if (_erreur != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
        ],
      ],
    );
  }
}
