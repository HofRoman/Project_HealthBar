import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/nutrition_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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

  static const int _calorieGoal = 2000;

  @override
  void initState() { super.initState(); _load(); }

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

  Future<void> _delete(int id) async { await _db.deleteNutrition(id); _load(); }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Mahlzeit hinzufügen', style: AppTheme.headline3),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(nameCtrl, 'Bezeichnung', 'z.B. Frühstück', Icons.restaurant),
            const SizedBox(height: 10),
            _field(calCtrl, 'Kalorien (kcal)', '300',
                Icons.local_fire_department, isNum: true),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _miniField(proteinCtrl, 'Protein g', '20')),
              const SizedBox(width: 8),
              Expanded(child: _miniField(carbsCtrl, 'Kohlenh. g', '40')),
              const SizedBox(width: 8),
              Expanded(child: _miniField(fatCtrl, 'Fett g', '10')),
            ]),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final cal = int.tryParse(calCtrl.text) ?? 0;
              if (name.isNotEmpty && cal > 0) {
                _db.insertNutrition(NutritionEntry(
                  mealName: name,
                  calories: cal,
                  protein: double.tryParse(proteinCtrl.text) ?? 0,
                  carbs: double.tryParse(carbsCtrl.text) ?? 0,
                  fat: double.tryParse(fatCtrl.text) ?? 0,
                  date: DateTime.now(),
                ).toMap());
                _load();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorFood,
                foregroundColor: Colors.white),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint,
      IconData icon, {bool isNum = false}) {
    return TextField(
      controller: c,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.colorFood, size: 18),
      ),
    );
  }

  Widget _miniField(TextEditingController c, String label, String hint) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalCalories / _calorieGoal).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.colorFood.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu,
                color: AppTheme.colorFood, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Ernährung'),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.colorFood,
        foregroundColor: AppTheme.bg,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(children: [
          // Kalorien-Karte
          GlassCard(
            glowColor: AppTheme.colorFood,
            glowIntensity: progress >= 1 ? 0.4 : 0.2,
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kalorien heute', style: AppTheme.caption),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalCalories',
                      style: const TextStyle(
                          color: AppTheme.colorFood,
                          fontSize: 48,
                          fontWeight: FontWeight.w900),
                    ),
                    Text('von $_calorieGoal kcal Tagesziel',
                        style: AppTheme.caption),
                  ],
                )),
                SizedBox(
                  width: 80, height: 80,
                  child: Stack(fit: StackFit.expand, children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.colorFood.withOpacity(0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.colorFood),
                      strokeWidth: 8,
                    ),
                    Center(child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                          color: AppTheme.colorFood,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    )),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              NeonProgressBar(value: progress, color: AppTheme.colorFood, height: 6),
              const SizedBox(height: 14),
              // Makros
              Row(children: [
                _MacroTile('Protein', '${_totalProtein.toStringAsFixed(0)}g',
                    AppTheme.neonBlue),
                const SizedBox(width: 8),
                _MacroTile('Kohlenh.', '${_totalCarbs.toStringAsFixed(0)}g',
                    AppTheme.grey70),
                const SizedBox(width: 8),
                _MacroTile('Fett', '${_totalFat.toStringAsFixed(0)}g',
                    AppTheme.colorSleep),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // Einträge
          if (_todayEntries.isEmpty)
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.restaurant, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text('Noch keine Mahlzeiten heute',
                      style: AppTheme.bodyBold),
                  const SizedBox(height: 6),
                  const Text('Tippe auf + um eine hinzuzufügen',
                      style: AppTheme.caption),
                ]),
              ),
            )
          else ...[
            const Text('Mahlzeiten heute', style: AppTheme.headline3),
            const SizedBox(height: 10),
            ..._todayEntries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                glowColor: AppTheme.colorFood,
                glowIntensity: 0.05,
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.colorFood.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant,
                        color: AppTheme.colorFood, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.mealName, style: AppTheme.bodyBold),
                      Text(
                        '${e.calories} kcal'
                        '${e.protein > 0 ? ' • P ${e.protein.toStringAsFixed(0)}g' : ''}'
                        '${e.carbs > 0 ? ' • K ${e.carbs.toStringAsFixed(0)}g' : ''}'
                        '${e.fat > 0 ? ' • F ${e.fat.toStringAsFixed(0)}g' : ''}',
                        style: AppTheme.caption,
                      ),
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

class _MacroTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
