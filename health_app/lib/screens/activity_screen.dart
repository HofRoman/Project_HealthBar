import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/activity_entry.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _db = DatabaseHelper();
  List<ActivityEntry> _todayActivities = [];
  int _totalCalories = 0;
  int _totalSteps = 0;
  int _totalMinutes = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _db.getActivitiesToday();
    final entries = data.map(ActivityEntry.fromMap).toList();
    setState(() {
      _todayActivities = entries;
      _totalCalories = entries.fold(0, (s, e) => s + e.caloriesBurned);
      _totalSteps = entries.fold(0, (s, e) => s + e.steps);
      _totalMinutes = entries.fold(0, (s, e) => s + e.durationMinutes);
    });
  }

  Future<void> _delete(int id) async {
    await _db.deleteActivity(id);
    _load();
  }

  Future<void> _showAddDialog() async {
    String selectedType = ActivityEntry.activityTypes.first;
    final durationController = TextEditingController();
    final stepsController = TextEditingController();
    double userWeight = 70.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Aktivität hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Aktivität',
                    border: OutlineInputBorder(),
                  ),
                  items: ActivityEntry.activityTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dauer (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stepsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Schritte (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                final dur = int.tryParse(durationController.text) ?? 0;
                if (dur > 0) {
                  final calories = ActivityEntry.estimateCalories(
                      selectedType, dur, userWeight);
                  final steps = int.tryParse(stepsController.text) ?? 0;
                  _db.insertActivity(ActivityEntry(
                    activityType: selectedType,
                    durationMinutes: dur,
                    caloriesBurned: calories,
                    steps: steps,
                    date: DateTime.now(),
                  ).toMap());
                  _load();
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35)),
              child: const Text('Speichern',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Aktivität'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFFF6B35),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats
            Row(
              children: [
                _MiniStat(
                  label: 'Kalorien',
                  value: '$_totalCalories',
                  unit: 'kcal',
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFFF6B35),
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Zeit',
                  value: '$_totalMinutes',
                  unit: 'min',
                  icon: Icons.timer,
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Schritte',
                  value: NumberFormat('#,###').format(_totalSteps),
                  unit: '',
                  icon: Icons.directions_walk,
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_todayActivities.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center,
                          size: 64,
                          color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Noch keine Aktivitäten heute',
                          style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 8),
                      Text('Tippe auf + um eine hinzuzufügen',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              )
            else ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Heute',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ..._todayActivities.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            e.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      title: Text(e.activityType,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${e.durationMinutes} min • ${e.caloriesBurned} kcal'
                          '${e.steps > 0 ? ' • ${e.steps} Schritte' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(e.date),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _delete(e.id!),
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color)),
            Text('$label ${unit.isNotEmpty ? "($unit)" : ""}',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
