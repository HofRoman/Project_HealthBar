import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/activity_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _db = DatabaseHelper();
  List<ActivityEntry> _entries = [];
  int _totalCal = 0, _totalSteps = 0, _totalMin = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _db.getActivitiesToday();
    final list = data.map(ActivityEntry.fromMap).toList();
    setState(() {
      _entries = list;
      _totalCal = list.fold(0, (s, e) => s + e.caloriesBurned);
      _totalSteps = list.fold(0, (s, e) => s + e.steps);
      _totalMin = list.fold(0, (s, e) => s + e.durationMinutes);
    });
  }

  Future<void> _delete(int id) async { await _db.deleteActivity(id); _load(); }

  Future<void> _showAdd() async {
    String selType = ActivityEntry.activityTypes.first;
    final durCtrl = TextEditingController();
    final stepsCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: const Text('Aktivität hinzufügen', style: AppTheme.headline3),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: selType,
                dropdownColor: AppTheme.bgCard,
                style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Aktivität'),
                items: ActivityEntry.activityTypes.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => set(() => selType = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Dauer (Minuten)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stepsCtrl,
                keyboardType: TextInputType.number,
                style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Schritte (optional)'),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen',
                    style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                final dur = int.tryParse(durCtrl.text) ?? 0;
                if (dur > 0) {
                  final cal = ActivityEntry.estimateCalories(selType, dur, 70.0);
                  final steps = int.tryParse(stepsCtrl.text) ?? 0;
                  _db.insertActivity(ActivityEntry(
                    activityType: selType,
                    durationMinutes: dur,
                    caloriesBurned: cal,
                    steps: steps,
                    date: DateTime.now(),
                  ).toMap());
                  _load();
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorActivity,
                  foregroundColor: Colors.white),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
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
              color: AppTheme.colorActivity.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center,
                color: AppTheme.colorActivity, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Aktivitätstracker'),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        backgroundColor: AppTheme.colorActivity,
        foregroundColor: AppTheme.bg,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(children: [
          // Stats
          Row(children: [
            _StatTile('Kalorien', '$_totalCal', 'kcal',
                Icons.local_fire_department, AppTheme.colorActivity),
            const SizedBox(width: 10),
            _StatTile('Zeit', '$_totalMin', 'min',
                Icons.timer, AppTheme.neonBlue),
            const SizedBox(width: 10),
            _StatTile('Schritte', NumberFormat('#,###').format(_totalSteps), '',
                Icons.directions_walk, AppTheme.colorScore),
          ]),
          const SizedBox(height: 14),

          if (_entries.isEmpty)
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.fitness_center, size: 64,
                      color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text('Noch keine Aktivitäten heute',
                      style: AppTheme.bodyBold),
                  const SizedBox(height: 6),
                  const Text('Tippe auf + um eine hinzuzufügen',
                      style: AppTheme.caption),
                ]),
              ),
            )
          else ...[
            const Text('Heute', style: AppTheme.headline3),
            const SizedBox(height: 10),
            ..._entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                glowColor: AppTheme.colorActivity,
                glowIntensity: 0.05,
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.colorActivity.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text(e.icon,
                            style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.activityType, style: AppTheme.bodyBold),
                      Text('${e.durationMinutes}min • ${e.caloriesBurned}kcal'
                          '${e.steps > 0 ? ' • ${e.steps} Schritte' : ''}',
                          style: AppTheme.caption),
                    ],
                  )),
                  Text(DateFormat('HH:mm').format(e.date),
                      style: AppTheme.caption),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.colorFood, size: 18),
                    onPressed: () => _delete(e.id!),
                  ),
                ]),
              ),
            )),
          ],
        ]),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.unit, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        glowColor: color,
        glowIntensity: 0.1,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          Text('$label${unit.isNotEmpty ? ' ($unit)' : ''}',
              style: AppTheme.caption.copyWith(fontSize: 10)),
        ]),
      ),
    );
  }
}
