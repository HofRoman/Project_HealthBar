import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/sleep_entry.dart';

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
  void initState() {
    super.initState();
    _load();
  }

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

    // Falls Einschlafen nach Aufwachen → nächster Tag
    if (wakeDt.isBefore(sleepDt)) {
      wakeDt = wakeDt.add(const Duration(days: 1));
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schlafeintrag gespeichert!'),
          backgroundColor: Color(0xFF9C27B0),
        ),
      );
    }
  }

  Future<void> _pickTime(bool isSleep) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleepTime : _wakeTime,
    );
    if (picked != null) {
      setState(() {
        if (isSleep) {
          _sleepTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  double get _avgSleep {
    if (_entries.isEmpty) return 0;
    return _entries.take(7).fold(0.0, (s, e) => s + e.durationHours) /
        _entries.take(7).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Schlaftracker'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Durchschnitt
            if (_entries.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.bedtime,
                          color: Color(0xFF9C27B0), size: 36),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ø Schlafdauer (7 Tage)',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                          Text(
                            '${_avgSleep.toStringAsFixed(1)} Stunden',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                          Text(
                            _avgSleep >= 7
                                ? 'Sehr gut!'
                                : _avgSleep >= 6
                                    ? 'Ausreichend'
                                    : 'Zu wenig Schlaf',
                            style: TextStyle(
                              color: _avgSleep >= 7
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF9800),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Eingabe
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schlaf eintragen',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerButton(
                            label: 'Eingeschlafen',
                            time: _sleepTime,
                            icon: Icons.nightlight_round,
                            color: const Color(0xFF5C35B0),
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePickerButton(
                            label: 'Aufgewacht',
                            time: _wakeTime,
                            icon: Icons.wb_sunny,
                            color: const Color(0xFFFF9800),
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Schlafqualität',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (i) {
                        final val = i + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _quality = val),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _quality == val
                                      ? const Color(0xFF9C27B0)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    ['😴', '😪', '😐', '🙂', '😊'][i],
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ['$val'][0],
                                style: TextStyle(
                                  color: _quality == val
                                      ? const Color(0xFF9C27B0)
                                      : Colors.grey,
                                  fontWeight: _quality == val
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Speichern'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Verlauf
            if (_entries.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Verlauf',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ..._entries.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(e.qualityEmoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      title: Text(e.durationFormatted,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(e.sleepStart)} – '
                        '${DateFormat('HH:mm').format(e.sleepEnd)} • ${e.qualityLabel}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('dd.MM').format(e.date),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 18),
                            onPressed: () async {
                              await _db.deleteSleep(e.id!);
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimePickerButton({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
