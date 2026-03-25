import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/sleep_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final _db = DatabaseHelper();
  List<SleepEntry> _entries = [];

  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  int _quality = 3;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _db.getSleepEntries();
    setState(() => _entries = data.map(SleepEntry.fromMap).toList());
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final sleepDt = DateTime(
        now.year, now.month, now.day, _sleepTime.hour, _sleepTime.minute);
    var wakeDt = DateTime(
        now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    if (wakeDt.isBefore(sleepDt)) wakeDt = wakeDt.add(const Duration(days: 1));
    final duration = wakeDt.difference(sleepDt).inMinutes / 60.0;

    await _db.insertSleep(SleepEntry(
      sleepStart: sleepDt,
      sleepEnd: wakeDt,
      durationHours: duration,
      quality: _quality,
      date: now,
    ).toMap());

    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Schlafeintrag gespeichert!'),
        backgroundColor: AppTheme.colorSleep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
      ));
    }
  }

  Future<void> _pickTime(bool isSleep) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleepTime : _wakeTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppTheme.colorSleep,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isSleep) _sleepTime = picked; else _wakeTime = picked;
      });
    }
  }

  double get _avgSleep {
    if (_entries.isEmpty) return 0;
    return _entries.take(7).fold(0.0, (s, e) => s + e.durationHours) /
        _entries.take(7).length;
  }

  double get _todayHours {
    if (_entries.isEmpty) return 0;
    return _entries.first.durationHours;
  }

  Color _qualityColor(int q) {
    if (q >= 4) return AppTheme.neonGreen;
    if (q >= 3) return AppTheme.neon;
    if (q >= 2) return AppTheme.grey70;
    return AppTheme.colorFood;
  }

  @override
  Widget build(BuildContext context) {
    final preview = _calcPreviewHours();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.colorSleep.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bedtime,
                color: AppTheme.colorSleep, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Schlaftracker'),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(children: [
          // Hauptanzeige
          GlassCard(
            glowColor: AppTheme.colorSleep,
            glowIntensity: _entries.isNotEmpty ? 0.2 : 0.1,
            child: Column(children: [
              const Icon(Icons.bedtime, color: AppTheme.colorSleep, size: 36),
              const SizedBox(height: 10),
              Text(
                _entries.isNotEmpty
                    ? '${_todayHours.toStringAsFixed(1)}h'
                    : '—',
                style: const TextStyle(
                    color: AppTheme.colorSleep,
                    fontSize: 52,
                    fontWeight: FontWeight.w900),
              ),
              Text('letzter Schlaf', style: AppTheme.caption),
              const SizedBox(height: 14),
              NeonProgressBar(
                value: (_todayHours / 8).clamp(0.0, 1.0),
                color: AppTheme.colorSleep,
                height: 10,
              ),
              const SizedBox(height: 8),
              if (_entries.isNotEmpty)
                Text(
                  _todayHours >= 7
                      ? 'Ausgezeichnet! Empfehlung erreicht.'
                      : _todayHours >= 6
                          ? 'Ausreichend — 7–8h wäre optimal'
                          : 'Zu wenig — unter 6h Schlaf',
                  style: TextStyle(
                    color: _todayHours >= 7
                        ? AppTheme.neonGreen
                        : _todayHours >= 6
                            ? AppTheme.neon
                            : AppTheme.colorFood,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              if (_entries.isNotEmpty) ...[
                const SizedBox(height: 12),
                const NeonDivider(),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.show_chart,
                      color: AppTheme.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Ø 7 Tage: ${_avgSleep.toStringAsFixed(1)}h',
                    style: AppTheme.caption,
                  ),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 14),

          // Eingabe
          GlassCard(
            glowColor: AppTheme.colorSleep,
            glowIntensity: 0.08,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Schlaf eintragen', style: AppTheme.bodyBold),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _TimeBtn(
                  label: 'Eingeschlafen',
                  time: _sleepTime,
                  icon: Icons.nightlight_round,
                  color: AppTheme.colorSleep,
                  onTap: () => _pickTime(true),
                )),
                const SizedBox(width: 10),
                Expanded(child: _TimeBtn(
                  label: 'Aufgewacht',
                  time: _wakeTime,
                  icon: Icons.wb_sunny_outlined,
                  color: AppTheme.grey70,
                  onTap: () => _pickTime(false),
                )),
              ]),
              if (preview > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.colorSleep.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '${preview.toStringAsFixed(1)} Stunden Schlaf',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.colorSleep,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Schlafqualität', style: AppTheme.bodyBold),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (i) {
                  final val = i + 1;
                  final active = _quality == val;
                  return GestureDetector(
                    onTap: () => setState(() => _quality = val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 58,
                      decoration: BoxDecoration(
                        color: active
                            ? _qualityColor(val).withOpacity(0.15)
                            : AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? _qualityColor(val).withOpacity(0.6)
                              : AppTheme.glassBorder,
                        ),
                        boxShadow: active
                            ? AppTheme.glow(_qualityColor(val), intensity: 0.2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(['😴', '😪', '😐', '🙂', '😊'][i],
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text('$val',
                              style: TextStyle(
                                color: active
                                    ? _qualityColor(val)
                                    : AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: active
                                    ? FontWeight.w800
                                    : FontWeight.normal,
                              )),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Speichern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorSleep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMid)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Verlauf
          if (_entries.isNotEmpty) ...[
            const Text('Verlauf', style: AppTheme.headline3),
            const SizedBox(height: 10),
            ..._entries.take(10).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                glowColor: _qualityColor(e.quality),
                glowIntensity: 0.05,
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _qualityColor(e.quality).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text(e.qualityEmoji,
                            style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.durationFormatted, style: AppTheme.bodyBold),
                      Text(
                        '${DateFormat('HH:mm').format(e.sleepStart)} – '
                        '${DateFormat('HH:mm').format(e.sleepEnd)} • ${e.qualityLabel}',
                        style: AppTheme.caption,
                      ),
                    ],
                  )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('dd.MM').format(e.date),
                          style: AppTheme.caption),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppTheme.colorFood, size: 18),
                        onPressed: () async {
                          await _db.deleteSleep(e.id!);
                          _load();
                        },
                      ),
                    ],
                  ),
                ]),
              ),
            )),
          ],
        ]),
      ),
    );
  }

  double _calcPreviewHours() {
    final now = DateTime.now();
    final sleepDt = DateTime(
        now.year, now.month, now.day, _sleepTime.hour, _sleepTime.minute);
    var wakeDt = DateTime(
        now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    if (wakeDt.isBefore(sleepDt)) wakeDt = wakeDt.add(const Duration(days: 1));
    return wakeDt.difference(sleepDt).inMinutes / 60.0;
  }
}

class _TimeBtn extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimeBtn({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            time.format(context),
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ]),
      ),
    );
  }
}
