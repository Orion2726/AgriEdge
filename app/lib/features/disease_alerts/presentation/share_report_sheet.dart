import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/ml/crop_catalog.dart';
import '../../../core/p2p/p2p_alert_service.dart';
import '../../../core/p2p/packet/p2p_packet.dart';
import '../../../core/settings/farm_setup.dart';
import '../../../shared/disease_label.dart';

Future<void> showShareReportSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _ShareReportSheet(),
    );

/// Labels from that crop's disease model, minus "healthy".
final _diseaseLabelsProvider = FutureProvider.family<List<String>, String>((ref, cropId) async {
  final raw = await rootBundle.loadString('assets/ml/disease/$cropId/labels.txt');
  return raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.toLowerCase().contains('healthy') && l.toLowerCase() != 'normal')
      .toList();
});

/// Shrinks a photo to a small JPEG thumbnail that fits in one quick BLE
/// transfer (≤ DiseaseAlertPayload.maxPhotoBytes).
Uint8List? makeShareThumbnail(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  for (final (width, quality) in [(240, 60), (200, 50), (160, 45), (120, 40)]) {
    final out = img.encodeJpg(img.copyResize(decoded, width: width), quality: quality);
    if (out.length <= DiseaseAlertPayload.maxPhotoBytes) return out;
  }
  return null;
}

class _ShareReportSheet extends ConsumerStatefulWidget {
  const _ShareReportSheet();
  @override
  ConsumerState<_ShareReportSheet> createState() => _ShareReportSheetState();
}

class _ShareReportSheetState extends ConsumerState<_ShareReportSheet> {
  String _cropId = cropCatalog.first.id;
  String? _label;
  String _severity = 'medium';
  final _note = TextEditingController();
  Uint8List? _photo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024);
    if (picked == null) return;
    final thumb = makeShareThumbnail(await picked.readAsBytes());
    setState(() {
      _photo = thumb;
      _error = thumb == null ? 'Could not use that photo. Try another one.' : null;
    });
  }

  void _fillExample() {
    setState(() {
      _cropId = 'potato';
      _label = 'Potato___Late_blight';
      _severity = 'high';
      _note.text = 'Dark water-soaked patches on lower leaves after 3 days of rain. '
          'About a quarter of my field affected. Spraying mancozeb tomorrow.';
    });
  }

  Future<({double lat, double lng})?> _location() async {
    final farm = ref.read(farmSetupProvider).location;
    if (farm != null) return (lat: farm.lat, lng: farm.lng);
    try {
      final p = await Geolocator.getLastKnownPosition();
      if (p != null) return (lat: p.latitude, lng: p.longitude);
    } catch (_) {}
    return null;
  }

  Future<void> _share() async {
    final label = _label;
    if (label == null) {
      setState(() => _error = 'Choose what you saw.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final loc = await _location();
    if (loc == null) {
      setState(() {
        _busy = false;
        _error = 'Set your farm location first (Home → My farm), so neighbours know where this is.';
      });
      return;
    }
    final service = await ref.read(p2pAlertServiceFutureProvider.future);
    await service.broadcastDetection(
      cropId: _cropId,
      label: label,
      confidence: 0, // a farmer's own report — no model confidence
      severity: _severity,
      lat: loc.lat,
      lng: loc.lng,
      note: _note.text,
      photoJpeg: _photo,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Report saved. It is shared with nearby phones when they are in range.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(_diseaseLabelsProvider(_cropId)).value ?? const <String>[];
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('Share a report', style: theme.textTheme.titleLarge)),
            TextButton.icon(onPressed: _fillExample, icon: const Icon(Icons.auto_fix_high), label: const Text('Fill example')),
          ]),
          Text('Tell nearby farmers what you see in your field. Works without internet.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _cropId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Crop'),
            items: [
              for (final c in cropCatalog)
                DropdownMenuItem(value: c.id, child: Text(c.displayName, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() {
              _cropId = v!;
              _label = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_cropId),
            initialValue: labels.contains(_label) ? _label : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'What did you see?'),
            items: [for (final l in labels) DropdownMenuItem(value: l, child: Text(prettyDiseaseLabel(l)))],
            onChanged: (v) => setState(() => _label = v),
          ),
          const SizedBox(height: 12),
          Text('How bad is it?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'low', label: Text('A little')),
              ButtonSegment(value: 'medium', label: Text('Spreading')),
              ButtonSegment(value: 'high', label: Text('Severe')),
            ],
            selected: {_severity},
            onSelectionChanged: (v) => setState(() => _severity = v.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: DiseaseAlertPayload.maxNoteLength,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Describe it (optional)', alignLabelWithHint: true),
          ),
          Row(children: [
            if (_photo != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_photo!, width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: IconButton(
                      tooltip: 'Remove photo',
                      icon: const Icon(Icons.cancel, size: 20),
                      onPressed: () => setState(() => _photo = null),
                    ),
                  ),
                ]),
              ),
            Expanded(
              child: Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera')),
                OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery')),
              ]),
            ),
          ]),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Share with nearby phones'),
          ),
        ]),
      ),
    );
  }
}
