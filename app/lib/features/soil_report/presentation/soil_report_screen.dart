import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/soil_report_repository.dart';

class SoilReportScreen extends ConsumerStatefulWidget {
  const SoilReportScreen({super.key});

  @override
  ConsumerState<SoilReportScreen> createState() => _SoilReportScreenState();
}

class _SoilReportScreenState extends ConsumerState<SoilReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nitrogen = TextEditingController();
  final _phosphorus = TextEditingController();
  final _potassium = TextEditingController();
  final _ph = TextEditingController();
  final _organicCarbon = TextEditingController();
  final _rainfall = TextEditingController(text: '0');
  final _temperature = TextEditingController(text: '0');
  final _humidity = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [
      _nitrogen,
      _phosphorus,
      _potassium,
      _ph,
      _organicCarbon,
      _rainfall,
      _temperature,
      _humidity,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _numberValidator(String? value, {double min = 0, double max = double.infinity}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a number';
    if (parsed < min || parsed > max) return 'Must be between $min and $max';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await ref.read(soilReportRepositoryProvider).submitReport(
          nitrogen: double.parse(_nitrogen.text),
          phosphorus: double.parse(_phosphorus.text),
          potassium: double.parse(_potassium.text),
          ph: double.parse(_ph.text),
          organicCarbon: double.parse(_organicCarbon.text),
          rainfallMm: double.parse(_rainfall.text),
          temperatureC: double.parse(_temperature.text),
          humidityPct: double.parse(_humidity.text),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Soil report saved. Crop recommendations updating...')),
    );
    context.push('/crop-recommendation');
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(soilReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Soil Test Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scan-to-fill from a physical SHC report is coming soon — enter values manually for now.')),
            ),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Scan physical report (coming soon)'),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _numField('Nitrogen (N, kg/ha)', _nitrogen, max: 600),
                _numField('Phosphorus (P, kg/ha)', _phosphorus, max: 300),
                _numField('Potassium (K, kg/ha)', _potassium, max: 600),
                _numField('Soil pH', _ph, max: 14),
                _numField('Organic Carbon (%)', _organicCarbon, max: 10),
                const Divider(height: 32),
                Text('Local climate (optional — improves recommendation accuracy)',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                _numField('Rainfall (mm, avg)', _rainfall, max: 5000),
                _numField('Temperature (°C, avg)', _temperature, min: -10, max: 55),
                _numField('Humidity (%, avg)', _humidity, max: 100),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit & get crop recommendations'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Past reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          history.when(
            data: (entries) => entries.isEmpty
                ? const Text('No reports submitted yet.')
                : Column(
                    children: entries
                        .map((e) => ListTile(
                              leading: Icon(
                                e.syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                color: e.syncStatus == 'synced' ? Colors.green : Colors.grey,
                              ),
                              title: Text('N:${e.nitrogen.toStringAsFixed(0)} P:${e.phosphorus.toStringAsFixed(0)} K:${e.potassium.toStringAsFixed(0)} pH:${e.ph.toStringAsFixed(1)}'),
                              subtitle: Text(DateFormat.yMMMd().add_jm().format(e.createdAt)),
                            ))
                        .toList(),
                  ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Could not load history: $e'),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller, {double min = 0, double max = double.infinity}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        validator: (v) => _numberValidator(v, min: min, max: max),
      ),
    );
  }
}
