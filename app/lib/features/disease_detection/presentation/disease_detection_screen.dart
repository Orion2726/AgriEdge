import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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

    final service = ref.read(tfliteDiseaseServiceProvider);
    final prediction = await service.predict(_image!);
    final advice = await ref.read(treatmentKnowledgeBaseProvider).lookup(prediction.label);

    if (!mounted) return;
    setState(() {
      _prediction = prediction;
      _advice = advice;
      _isRunning = false;
    });
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
        // Location unavailable — still save the detection, just without a geotag.
      }
    }
    await ref.read(diseaseDetectionRepositoryProvider).recordDetection(
          label: prediction.label,
          confidence: prediction.confidence,
          isMock: prediction.isMock,
          imagePath: _image?.path,
          lat: lat,
          lng: lng,
          consentShared: _consentShared,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detection saved. It will sync when you\'re online.')),
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
      appBar: AppBar(title: const Text('Disease Prediction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              advice?.disease ?? prediction.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%'),
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        entry.syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_upload_outlined,
        color: entry.syncStatus == 'synced' ? Colors.green : Colors.grey,
      ),
      title: Text(entry.label),
      subtitle: Text(DateFormat.yMMMd().add_jm().format(entry.createdAt)),
      trailing: Text('${(entry.confidence * 100).toStringAsFixed(0)}%'),
    );
  }
}
