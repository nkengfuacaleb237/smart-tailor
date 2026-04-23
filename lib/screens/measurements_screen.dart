import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'camera_measurement_screen.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  List _measurements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeasurements();
  }

  Future<void> _fetchMeasurements() async {
    final userId = Provider.of<AppState>(context, listen: false).userId;
    try {
      final res = await http.get(
        Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/measurements/user/'));
      setState(() {
        _measurements = jsonDecode(res.body);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMeasurement(int id) async {
    await http.delete(
      Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/measurements/$id'));
    _fetchMeasurements();
  }

  void _showEditDialog(Map m) {
    final chestCtrl = TextEditingController(text: m['chest'].toString());
    final waistCtrl = TextEditingController(text: m['waist'].toString());
    final hipsCtrl = TextEditingController(text: m['hips'].toString());
    final shoulderCtrl = TextEditingController(text: m['shoulder'].toString());
    final sleeveCtrl = TextEditingController(text: m['sleeve'].toString());
    final inseamCtrl = TextEditingController(text: m['inseam'].toString());
    final notesCtrl = TextEditingController(text: m['notes'] ?? '');
    final labelCtrl = TextEditingController(text: m['label'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Measurement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E))),
              const SizedBox(height: 16),
              TextField(controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: chestCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Chest (cm)'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: waistCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Waist (cm)'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: hipsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hips (cm)'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: shoulderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Shoulder (cm)'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: sleeveCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sleeve (cm)'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: inseamCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Inseam (cm)'))),
              ]),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await http.put(
                      Uri.parse('https://smart-tailor-backend-mi4z.onrender.com/api/measurements//edit'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'chest': double.tryParse(chestCtrl.text) ?? 0,
                        'waist': double.tryParse(waistCtrl.text) ?? 0,
                        'hips': double.tryParse(hipsCtrl.text) ?? 0,
                        'shoulder': double.tryParse(shoulderCtrl.text) ?? 0,
                        'sleeve': double.tryParse(sleeveCtrl.text) ?? 0,
                        'inseam': double.tryParse(inseamCtrl.text) ?? 0,
                        'notes': notesCtrl.text,
                        'label': labelCtrl.text,
                      }),
                    );
                    Navigator.pop(ctx);
                    _fetchMeasurements();
                  },
                  child: const Text('SAVE CHANGES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Measurements',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E), letterSpacing: -0.5)),
                      Text('Your body measurements',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CameraMeasurementScreen()));
                      _fetchMeasurements();
                    },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _measurements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.straighten_outlined,
                            size: 60, color: Color(0xFFE5E5EA)),
                          const SizedBox(height: 16),
                          const Text('No measurements yet',
                            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Tap the camera to scan your body',
                            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const CameraMeasurementScreen()));
                              _fetchMeasurements();
                            },
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Scan Now'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _measurements.length,
                      itemBuilder: (ctx, i) {
                        final m = _measurements[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.straighten,
                                        color: Color(0xFF1B5E20), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(m['label'] ?? 'Body Scan',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15, color: Color(0xFF1C1C1E))),
                                          Text(m['created_at']?.toString().substring(0, 10) ?? '',
                                            style: const TextStyle(
                                              color: Color(0xFF8E8E93), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                        color: Color(0xFF1B5E20), size: 20),
                                      onPressed: () => _showEditDialog(m),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                      onPressed: () => _deleteMeasurement(m['id']),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFE5E5EA)),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _MeasurementChip('Chest', ''),
                                    _MeasurementChip('Waist', ''),
                                    _MeasurementChip('Hips', ''),
                                    _MeasurementChip('Shoulder', ''),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementChip extends StatelessWidget {
  final String label;
  final String value;
  const _MeasurementChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20))),
        Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
      ],
    );
  }
}
