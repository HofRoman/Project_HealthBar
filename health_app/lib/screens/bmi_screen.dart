import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/bmi_entry.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _db = DatabaseHelper();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double? _calculatedBmi;
  List<BmiEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final data = await _db.getBmiEntries();
    setState(() {
      _history = data.map(BmiEntry.fromMap).toList();
    });
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.parse(_weightController.text.replaceAll(',', '.'));
    final height = double.parse(_heightController.text.replaceAll(',', '.'));
    final bmi = BmiEntry.calculate(weight, height);

    final entry = BmiEntry(
      weight: weight,
      height: height,
      bmi: bmi,
      date: DateTime.now(),
    );

    await _db.insertBmi(entry.toMap());
    await _loadHistory();

    setState(() => _calculatedBmi = bmi);
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFFFF9800);
    if (bmi < 25.0) return const Color(0xFF4CAF50);
    if (bmi < 30.0) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('BMI Rechner'),
        backgroundColor: const Color(0xFF2E7D5B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Eingabe-Karte
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deine Daten eingeben',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _weightController,
                        label: 'Gewicht (kg)',
                        hint: 'z.B. 70.5',
                        icon: Icons.monitor_weight,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _heightController,
                        label: 'Körpergröße (cm)',
                        hint: 'z.B. 175',
                        icon: Icons.height,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _calculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D5B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('BMI Berechnen',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Ergebnis
            if (_calculatedBmi != null) ...[
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Dein BMI',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        _calculatedBmi!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: _bmiColor(_calculatedBmi!),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              _bmiColor(_calculatedBmi!).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          BmiEntry(
                                  weight: 0,
                                  height: 0,
                                  bmi: _calculatedBmi!,
                                  date: DateTime.now())
                              .category,
                          style: TextStyle(
                            color: _bmiColor(_calculatedBmi!),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _BmiScale(bmi: _calculatedBmi!),
                    ],
                  ),
                ),
              ),
            ],
            // Verlauf
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Verlauf',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ..._history.take(10).map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _bmiColor(e.bmi).withOpacity(0.15),
                        child: Text(
                          e.bmi.toStringAsFixed(1),
                          style: TextStyle(
                              color: _bmiColor(e.bmi),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      title: Text(e.category,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${e.weight} kg • ${e.height} cm'),
                      trailing: Text(
                        DateFormat('dd.MM.yy').format(e.date),
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D5B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF2E7D5B), width: 2),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Bitte eingeben';
        final n = double.tryParse(val.replaceAll(',', '.'));
        if (n == null || n <= 0) return 'Ungültige Zahl';
        return null;
      },
    );
  }
}

class _BmiScale extends StatelessWidget {
  final double bmi;
  const _BmiScale({required this.bmi});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _ScaleSegment('< 18.5\nUntergewicht', const Color(0xFF2196F3), 1),
            _ScaleSegment('18.5–24.9\nNormal', const Color(0xFF4CAF50), 1),
            _ScaleSegment('25–29.9\nÜbergewicht', const Color(0xFFFF9800), 1),
            _ScaleSegment('≥ 30\nAdiposi.', const Color(0xFFF44336), 1),
          ],
        ),
      ],
    );
  }
}

class _ScaleSegment extends StatelessWidget {
  final String label;
  final Color color;
  final int flex;
  const _ScaleSegment(this.label, this.color, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.2)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
