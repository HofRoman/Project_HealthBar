import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/vitals_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  List<VitalsEntry> _entries = [];

  late TabController _tabCtrl;

  // Form-Controller
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _sysCtrl.dispose(); _diaCtrl.dispose(); _hrCtrl.dispose();
    _spo2Ctrl.dispose(); _tempCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _db.getVitalsEntries();
    setState(() => _entries = data.map(VitalsEntry.fromMap).toList());
  }

  Future<void> _save() async {
    final sys = int.tryParse(_sysCtrl.text);
    final dia = int.tryParse(_diaCtrl.text);
    final hr = int.tryParse(_hrCtrl.text);
    final spo2 = int.tryParse(_spo2Ctrl.text);
    final temp = double.tryParse(_tempCtrl.text.replaceAll(',', '.'));

    if (sys == null && dia == null && hr == null && spo2 == null && temp == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bitte mindestens einen Wert eingeben'),
        backgroundColor: AppTheme.colorEmergency,
      ));
      return;
    }

    await _db.insertVitals(VitalsEntry(
      systolic: sys, diastolic: dia, heartRate: hr,
      spo2: spo2, temperature: temp,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      date: DateTime.now(),
    ).toMap());

    _sysCtrl.clear(); _diaCtrl.clear(); _hrCtrl.clear();
    _spo2Ctrl.clear(); _tempCtrl.clear(); _notesCtrl.clear();
    _load();
    _tabCtrl.animateTo(1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vitalzeichen gespeichert!'),
        backgroundColor: AppTheme.colorVitals,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
      ));
    }
  }

  VitalsEntry? get _latest => _entries.isNotEmpty ? _entries.first : null;

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
              color: AppTheme.colorVitals.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.monitor_heart,
                color: AppTheme.colorVitals, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Vitalzeichen'),
        ]),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.colorVitals,
          labelColor: AppTheme.colorVitals,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Erfassen'),
            Tab(text: 'Verlauf'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildInput(), _buildHistory()],
      ),
    );
  }

  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(children: [
        // Letzter Messwert
        if (_latest != null)
          GlassCard(
            glowColor: AppTheme.colorVitals,
            glowIntensity: 0.15,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.access_time,
                    color: AppTheme.colorVitals, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Letzte Messung · ${DateFormat('dd.MM HH:mm').format(_latest!.date)}',
                  style: AppTheme.caption,
                ),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (_latest!.systolic != null)
                    _MiniStat('Blutdruck', _latest!.bpFormatted,
                        AppTheme.colorVitals),
                  if (_latest!.heartRate != null)
                    _MiniStat('Puls', '${_latest!.heartRate} bpm',
                        AppTheme.colorFood),
                  if (_latest!.spo2 != null)
                    _MiniStat('SpO₂', '${_latest!.spo2}%', AppTheme.neonBlue),
                  if (_latest!.temperature != null)
                    _MiniStat('Temp', '${_latest!.temperature!.toStringAsFixed(1)}°C',
                        AppTheme.colorActivity),
                ],
              ),
              if (_latest!.systolic != null) ...[
                const SizedBox(height: 8),
                NeonBadge(_latest!.bpCategory,
                    color: _bpColor(_latest!.systolic!, _latest!.diastolic!)),
              ],
            ]),
          ),
        const SizedBox(height: 14),

        // Blutdruck
        GlassCard(
          glowColor: AppTheme.colorVitals,
          glowIntensity: 0.06,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionHeader(Icons.bloodtype, 'Blutdruck', AppTheme.colorVitals),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Input(
                ctrl: _sysCtrl,
                label: 'Systolisch',
                hint: '120',
                unit: 'mmHg',
                color: AppTheme.colorVitals,
              )),
              const SizedBox(width: 10),
              Expanded(child: _Input(
                ctrl: _diaCtrl,
                label: 'Diastolisch',
                hint: '80',
                unit: 'mmHg',
                color: AppTheme.colorVitals,
              )),
            ]),
            const SizedBox(height: 8),
            // Referenztabelle
            _BpRefRow('Optimal', '< 120/80', AppTheme.neonGreen),
            _BpRefRow('Normal', '< 130/85', AppTheme.neon),
            _BpRefRow('Hochnormal', '< 140/90', const Color(0xFFFFB300)),
            _BpRefRow('Hypertonie', '≥ 140/90', AppTheme.colorFood),
          ]),
        ),
        const SizedBox(height: 12),

        // Puls & SpO2
        GlassCard(
          glowColor: AppTheme.colorFood,
          glowIntensity: 0.06,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionHeader(Icons.favorite, 'Herzfrequenz & Sauerstoff',
                AppTheme.colorFood),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Input(
                ctrl: _hrCtrl,
                label: 'Herzfrequenz',
                hint: '70',
                unit: 'bpm',
                color: AppTheme.colorFood,
              )),
              const SizedBox(width: 10),
              Expanded(child: _Input(
                ctrl: _spo2Ctrl,
                label: 'Sauerstoff SpO₂',
                hint: '98',
                unit: '%',
                color: AppTheme.neonBlue,
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Temperatur
        GlassCard(
          glowColor: AppTheme.colorActivity,
          glowIntensity: 0.06,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionHeader(Icons.thermostat, 'Körpertemperatur',
                AppTheme.colorActivity),
            const SizedBox(height: 12),
            _Input(
              ctrl: _tempCtrl,
              label: 'Temperatur',
              hint: '36.6',
              unit: '°C',
              color: AppTheme.colorActivity,
            ),
            const SizedBox(height: 6),
            Row(children: [
              _TempRef('< 36.1°', 'Hypothermie', AppTheme.neonBlue),
              _TempRef('36.1–37.2°', 'Normal', AppTheme.neonGreen),
              _TempRef('37.3–38°', 'Erhöht', const Color(0xFFFFB300)),
              _TempRef('> 38°', 'Fieber', AppTheme.colorFood),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Notizen
        GlassCard(
          child: TextField(
            controller: _notesCtrl,
            maxLines: 2,
            style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Notizen (optional)',
              hintText: 'z.B. nach Sport, vor dem Schlafen...',
              prefixIcon: Icon(Icons.edit_note, color: AppTheme.neon, size: 20),
              border: InputBorder.none,
              fillColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('Messung speichern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorVitals,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMid)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHistory() {
    if (_entries.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monitor_heart_outlined,
              size: 72, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('Noch keine Messungen', style: AppTheme.bodyBold),
          const SizedBox(height: 6),
          const Text('Erfasse deine ersten Vitalzeichen',
              style: AppTheme.caption),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: _entries.length,
      itemBuilder: (_, i) {
        final e = _entries[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            glowColor: AppTheme.colorVitals,
            glowIntensity: 0.05,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.access_time,
                    size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 5),
                Text(DateFormat('dd.MM.yyyy HH:mm').format(e.date),
                    style: AppTheme.caption),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await _db.deleteVitals(e.id!);
                    _load();
                  },
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.colorFood),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 8, children: [
                if (e.systolic != null)
                  _VitalChip(Icons.bloodtype, e.bpFormatted,
                      AppTheme.colorVitals),
                if (e.heartRate != null)
                  _VitalChip(Icons.favorite, '${e.heartRate} bpm',
                      AppTheme.colorFood),
                if (e.spo2 != null)
                  _VitalChip(Icons.air, '${e.spo2}% SpO₂',
                      AppTheme.neonBlue),
                if (e.temperature != null)
                  _VitalChip(Icons.thermostat,
                      '${e.temperature!.toStringAsFixed(1)}°C',
                      AppTheme.colorActivity),
              ]),
              if (e.bpCategory.isNotEmpty) ...[
                const SizedBox(height: 8),
                NeonBadge(e.bpCategory,
                    color: _bpColor(e.systolic!, e.diastolic!)),
              ],
              if (e.notes != null) ...[
                const SizedBox(height: 6),
                Text(e.notes!, style: AppTheme.caption),
              ],
            ]),
          ),
        );
      },
    );
  }

  Color _bpColor(int sys, int dia) {
    if (sys < 120 && dia < 80) return AppTheme.neonGreen;
    if (sys < 130 && dia < 85) return AppTheme.neon;
    if (sys < 140 && dia < 90) return const Color(0xFFFFB300);
    return AppTheme.colorFood;
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(this.icon, this.title, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 18),
    const SizedBox(width: 8),
    Text(title, style: AppTheme.bodyBold.copyWith(color: color)),
  ]);
}

class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint, unit;
  final Color color;
  const _Input({required this.ctrl, required this.label,
      required this.hint, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        suffixStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 14)),
      Text(label, style: AppTheme.caption),
    ]);
  }
}

class _BpRefRow extends StatelessWidget {
  final String label, range;
  final Color color;
  const _BpRefRow(this.label, this.range, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.caption.copyWith(color: color)),
        const SizedBox(width: 6),
        Text(range, style: AppTheme.caption),
      ]),
    );
  }
}

class _TempRef extends StatelessWidget {
  final String range, label;
  final Color color;
  const _TempRef(this.range, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(range,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        Text(label,
            style: AppTheme.caption.copyWith(fontSize: 8),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _VitalChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
