import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/nutrition_entry.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _db = DatabaseHelper();
  List<NutritionEntry> _todayEntries = [];
  int _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  final int _calorieGoal = 2000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _db.getNutritionToday();
    final entries = data.map(NutritionEntry.fromMap).toList();
    setState(() {
      _todayEntries = entries;
      _totalCalories = entries.fold(0, (s, e) => s + e.calories);
      _totalProtein = entries.fold(0.0, (s, e) => s + e.protein);
      _totalCarbs = entries.fold(0.0, (s, e) => s + e.carbs);
      _totalFat = entries.fold(0.0, (s, e) => s + e.fat);
    });
  }

  Future<void> _delete(int id) async {
    await _db.deleteNutrition(id);
    _load();
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mahlzeit hinzufügen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(controller: nameController, label: 'Bezeichnung',
                  hint: 'z.B. Frühstück, Mittagessen'),
              const SizedBox(height: 10),
              _DialogField(controller: calController, label: 'Kalorien (kcal)',
                  hint: '300', isNum: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _DialogField(
                      controller: proteinController, label: 'Protein (g)',
                      hint: '20', isNum: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _DialogField(
                      controller: carbsController, label: 'Kohlenh. (g)',
                      hint: '40', isNum: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _DialogField(
                      controller: fatController, label: 'Fett (g)',
                      hint: '10', isNum: true)),
                ],
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
              final name = nameController.text.trim();
              final cal = int.tryParse(calController.text) ?? 0;
              if (name.isNotEmpty && cal > 0) {
                _db.insertNutrition(NutritionEntry(
                  mealName: name,
                  calories: cal,
                  protein: double.tryParse(proteinController.text) ?? 0,
                  carbs: double.tryParse(carbsController.text) ?? 0,
                  fat: double.tryParse(fatController.text) ?? 0,
                  date: DateTime.now(),
                ).toMap());
                _load();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336)),
            child: const Text('Hinzufügen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalCalories / _calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ernährung'),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFF44336),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Kalorienkarte
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kalorien heute',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                            Text(
                              '$_totalCalories',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF44336),
                              ),
                            ),
                            Text('von $_calorieGoal kcal Ziel',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFF44336)),
                                strokeWidth: 8,
                              ),
                              Center(
                                child: Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFFF44336)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Makronährstoffe
                    Row(
                      children: [
                        _MacroChip('Protein',
                            '${_totalProtein.toStringAsFixed(0)}g',
                            const Color(0xFF2196F3)),
                        const SizedBox(width: 8),
                        _MacroChip('Kohlenh.',
                            '${_totalCarbs.toStringAsFixed(0)}g',
                            const Color(0xFFFF9800)),
                        const SizedBox(width: 8),
                        _MacroChip('Fett',
                            '${_totalFat.toStringAsFixed(0)}g',
                            const Color(0xFF9C27B0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Einträge
            if (_todayEntries.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Noch keine Mahlzeiten heute',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            else ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mahlzeiten heute',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ..._todayEntries.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant,
                            color: Color(0xFFF44336)),
                      ),
                      title: Text(e.mealName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${e.calories} kcal'
                        '${e.protein > 0 ? ' • P: ${e.protein.toStringAsFixed(0)}g' : ''}'
                        '${e.carbs > 0 ? ' • K: ${e.carbs.toStringAsFixed(0)}g' : ''}'
                        '${e.fat > 0 ? ' • F: ${e.fat.toStringAsFixed(0)}g' : ''}',
                      ),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label,
                style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isNum;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isNum = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
