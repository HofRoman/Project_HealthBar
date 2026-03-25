import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/bmi_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _db = DatabaseHelper();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double? _calcBmi;
  List<BmiEntry> _history = [];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _weightCtrl.dispose(); _heightCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final data = await _db.getBmiEntries();
    setState(() => _history = data.map(BmiEntry.fromMap).toList());
  }

  Future<void> _calc() async {
    if (!_formKey.currentState!.validate()) return;
    final w = double.parse(_weightCtrl.text.replaceAll(',', '.'));
    final h = double.parse(_heightCtrl.text.replaceAll(',', '.'));
    final bmi = BmiEntry.calculate(w, h);
    await _db.insertBmi(BmiEntry(weight: w, height: h, bmi: bmi, date: DateTime.now()).toMap());
    await _load();
    setState(() => _calcBmi = bmi);
  }

  Color _color(double b) {
    if (b < 18.5) return AppTheme.neonBlue;
    if (b < 25)   return AppTheme.neonGreen;
    if (b < 30)   return AppTheme.grey70;
    return AppTheme.colorFood;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.colorBmi.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.monitor_weight,
                color: AppTheme.colorBmi, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('BMI Rechner'),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(children: [
          // Eingabe
          GlassCard(
            glowColor: AppTheme.colorBmi,
            glowIntensity: 0.1,
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Deine Körperwerte', style: AppTheme.bodyBold),
                const SizedBox(height: 14),
                _field(_weightCtrl, 'Gewicht (kg)', 'z.B. 70.5', Icons.monitor_weight),
                const SizedBox(height: 12),
                _field(_heightCtrl, 'Körpergröße (cm)', 'z.B. 175', Icons.height),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calc,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorBmi,
                      foregroundColor: AppTheme.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMid)),
                    ),
                    child: const Text('BMI Berechnen',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ]),
            ),
          ),

          // Ergebnis
          if (_calcBmi != null) ...[
            const SizedBox(height: 14),
            GlassCard(
              glowColor: _color(_calcBmi!),
              glowIntensity: 0.3,
              child: Column(children: [
                Text('Dein BMI', style: AppTheme.caption),
                const SizedBox(height: 6),
                Text(
                  _calcBmi!.toStringAsFixed(1),
                  style: TextStyle(
                      color: _color(_calcBmi!),
                      fontSize: 64,
                      fontWeight: FontWeight.w900),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _color(_calcBmi!).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _color(_calcBmi!).withOpacity(0.4)),
                  ),
                  child: Text(
                    BmiEntry(weight: 0, height: 0, bmi: _calcBmi!, date: DateTime.now()).category,
                    style: TextStyle(
                        color: _color(_calcBmi!),
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
                const SizedBox(height: 16),
                _BmiScale(bmi: _calcBmi!),
              ]),
            ),
          ],

          // Verlauf
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Verlauf', style: AppTheme.headline3),
            const SizedBox(height: 10),
            ..._history.take(10).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                glowColor: _color(e.bmi),
                glowIntensity: 0.05,
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _color(e.bmi).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _color(e.bmi).withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text(e.bmi.toStringAsFixed(1),
                          style: TextStyle(
                              color: _color(e.bmi),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.category, style: AppTheme.bodyBold),
                      Text('${e.weight} kg • ${e.height} cm', style: AppTheme.caption),
                    ],
                  )),
                  Text(DateFormat('dd.MM.yy').format(e.date),
                      style: AppTheme.caption),
                ]),
              ),
            )),
          ],
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.colorBmi, size: 18),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Bitte eingeben';
        final n = double.tryParse(v.replaceAll(',', '.'));
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
    const segments = [
      ('< 18.5\nUntergewicht', AppTheme.neonBlue),
      ('18.5–24.9\nNormal', AppTheme.neonGreen),
      ('25–29.9\nÜbergewicht', AppTheme.grey70),
      ('≥ 30\nAdiposi.', AppTheme.colorFood),
    ];
    return Column(children: [
      const NeonDivider(),
      const SizedBox(height: 10),
      Row(children: segments.map((s) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: s.$2.withOpacity(0.12),
            border: Border.all(color: s.$2.withOpacity(0.3)),
          ),
          child: Text(s.$1,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: s.$2,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ),
      )).toList()),
    ]);
  }
}
