import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/ml/crop_catalog.dart';
import '../../../core/p2p/p2p_alert_service.dart';
import '../../../core/settings/farm_setup.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../shared/disease_label.dart';
import '../../disease_alerts/presentation/share_report_sheet.dart' show makeSharePhoto;
import '../data/disease_detection_repository.dart';
import '../data/treatment_knowledge_base.dart';
import '../domain/disease_detection_entry.dart';
import '../ml/tflite_disease_service.dart';

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  ConsumerState<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends ConsumerState<DiseaseDetectionScreen> {
  File? _image;
  DiseasePrediction? _prediction;
  TreatmentAdvice? _advice;
  bool _isRunning = false;
  bool _consentShared = false;
  String _cropId = cropCatalog.first.id;

  Future<void> _capture(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1600);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _prediction = null;
      _advice = null;
      _isRunning = true;
    });

    try {
      final service = ref.read(tfliteDiseaseServiceProvider);
      final prediction = await service.predict(_cropId, _image!);
      final advice = await ref.read(treatmentKnowledgeBaseProvider).lookup(_cropId, prediction.label);
      if (!mounted) return;
      setState(() {
        _prediction = prediction;
        _advice = advice;
        _isRunning = false;
      });
    } catch (e, st) {
      debugPrint('disease check failed for $_cropId: $e\n$st');
      // Never leave the spinner running: say what happened instead.
      if (!mounted) return;
      setState(() => _isRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is FormatException
            ? 'That photo could not be read. Try another one.'
            : 'Could not check this photo: $e'),
      ));
    }
  }

  Future<void> _saveDetection() async {
    final prediction = _prediction;
    if (prediction == null) return;
    double? lat, lng;
    if (_consentShared) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final position = await Geolocator.getCurrentPosition();
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {
        // No GPS fix — fall back to the farm location chosen in setup.
        final farm = ref.read(farmSetupProvider).location;
        lat = farm?.lat;
        lng = farm?.lng;
      }
    }
    final entry = await ref.read(diseaseDetectionRepositoryProvider).recordDetection(
          cropId: _cropId,
          label: prediction.label,
          confidence: prediction.confidence,
          isMock: prediction.isMock,
          imagePath: _image?.path,
          lat: lat,
          lng: lng,
          consentShared: _consentShared,
        );

    // Best-effort P2P broadcast — see docs/P2P_ALERT_PROTOCOL.md. Requires
    // consent + a geotag + a real (non-mock) result, and skips "healthy"
    // results since there's nothing to alert neighbors about. Swallows
    // failures (e.g. the P2P session isn't running because the farmer
    // hasn't opened the nearby-alerts screen this session) — this must
    // never block saving the detection itself.
    final isHealthy =
        prediction.label.toLowerCase().contains('healthy') || prediction.label.toLowerCase() == 'normal';
    if (_consentShared && !prediction.isMock && !isHealthy && lat != null && lng != null) {
      try {
        final p2pService = await ref.read(p2pAlertServiceFutureProvider.future);
        await p2pService.broadcastDetection(
          cropId: _cropId,
          label: prediction.label,
          confidence: prediction.confidence,
          severity: prediction.confidence >= 0.75
              ? 'high'
              : prediction.confidence >= 0.5
                  ? 'medium'
                  : 'low',
          lat: lat,
          lng: lng,
          detectionId: entry.id,
          photoJpeg: _image == null ? null : makeSharePhoto(await _image!.readAsBytes()),
        );
      } catch (_) {
        // Non-fatal — the detection is already saved and will still sync
        // to the backend normally; nearby-device propagation is best-effort.
      }
    }

    // Upload now if online; stays queued otherwise.
    final sync = ref.read(syncManagerProvider);
    unawaited(sync.syncDomain('detections').then((_) => sync.syncDomain('p2p_alerts')));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_consentShared && lat != null
            ? 'Saved. Shared with nearby phones when they are in range, and uploaded when online.'
            : 'Saved on this phone. It will upload when you are online.'),
      ),
    );
    setState(() {
      _image = null;
      _prediction = null;
      _advice = null;
      _consentShared = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(diseaseDetectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Check a sick plant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _cropId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Crop',
              border: OutlineInputBorder(),
            ),
            items: cropCatalog
                .map((crop) => DropdownMenuItem(
                      value: crop.id,
                      child: Text(
                        crop.displayName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ))
                .toList(),
            onChanged: _isRunning
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _cropId = value;
                      _image = null;
                      _prediction = null;
                      _advice = null;
                    });
                  },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _capture(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _capture(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_image!, height: 220, fit: BoxFit.cover),
            ),
          if (_isRunning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_prediction != null) _ResultCard(
            prediction: _prediction!,
            advice: _advice,
            consentShared: _consentShared,
            onConsentChanged: (v) => setState(() => _consentShared = v),
            onSave: _saveDetection,
          ),
          const SizedBox(height: 24),
          Text('Recent detections', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          history.when(
            data: (entries) => entries.isEmpty
                ? const Text('No detections yet.')
                : Column(
                    children: entries
                        .map((e) => _HistoryTile(entry: e))
                        .toList(growable: false),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load history: $e'),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.prediction,
    required this.advice,
    required this.consentShared,
    required this.onConsentChanged,
    required this.onSave,
  });

  final DiseasePrediction prediction;
  final TreatmentAdvice? advice;
  final bool consentShared;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prediction.isMock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MOCK RESULT — no trained model installed yet',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              advice?.disease ?? prettyDiseaseLabel(prediction.label),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%'),
            if (!prediction.isMock && !prediction.isConfident)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Not sure. It could be ${prettyDiseaseLabel(prediction.label)} '
                  '(${(prediction.confidence * 100).round()}%)'
                  '${prediction.runnerUpLabel == null ? '' : ' or ${prettyDiseaseLabel(prediction.runnerUpLabel!)} (${(prediction.runnerUpConfidence! * 100).round()}%)'}. '
                  'For a better answer, take a close, sharp photo of one affected leaf in daylight.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                ),
              ),
            if (advice != null) ...[
              const SizedBox(height: 12),
              Text('Symptoms', style: Theme.of(context).textTheme.labelLarge),
              Text(advice!.symptoms),
              const SizedBox(height: 8),
              Text('Treatment', style: Theme.of(context).textTheme.labelLarge),
              Text(advice!.treatment),
              const SizedBox(height: 8),
              Text('Prevention', style: Theme.of(context).textTheme.labelLarge),
              Text(advice!.prevention),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: consentShared,
              onChanged: (v) => onConsentChanged(v ?? false),
              title: const Text('Share this detection (with location) to help nearby-alert map'),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onSave, child: const Text('Save detection')),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final DiseaseDetectionEntry entry;

  String _cropDisplayName(String cropId) {
    for (final crop in cropCatalog) {
      if (crop.id == cropId) return crop.displayName;
    }
    return cropId;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        entry.syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_upload_outlined,
        color: entry.syncStatus == 'synced' ? Colors.green : Colors.grey,
      ),
      title: Text(prettyDiseaseLabel(entry.label)),
      subtitle: Text(
        '${_cropDisplayName(entry.cropId)} · ${DateFormat.yMMMd().add_jm().format(entry.createdAt)}',
      ),
      trailing: Text('${(entry.confidence * 100).toStringAsFixed(0)}%'),
    );
  }
}
