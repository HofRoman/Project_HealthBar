import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/water_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _db = DatabaseHelper();
  List<WaterEntry> _entries = [];
  int _total = 0;
  static const int _goal = 2500;
  static const _quick = [150, 200, 300, 500];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _db.getWaterToday();
    final list = data.map(WaterEntry.fromMap).toList();
    setState(() { _entries = list; _total = list.fold(0, (s, e) => s + e.amountMl); });
  }

  Future<void> _add(int ml) async {
    await _db.insertWater(WaterEntry(amountMl: ml, date: DateTime.now()).toMap());
    _load();
  }

  Future<void> _delete(int id) async { await _db.deleteWaterEntry(id); _load(); }

  Future<void> _customDialog() async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Eigene Menge', style: AppTheme.headline3),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Menge in ml'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(c.text);
              if (ml != null && ml > 0) { _add(ml); Navigator.pop(ctx); }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorWater,
                foregroundColor: AppTheme.bg),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_total / _goal).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.colorWater.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop,
                color: AppTheme.colorWater, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Wassertracker'),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(children: [
          // Hauptanzeige
          GlassCard(
            glowColor: AppTheme.colorWater,
            glowIntensity: progress >= 1 ? 0.4 : 0.2,
            child: Column(children: [
              const Icon(Icons.water_drop, color: AppTheme.colorWater, size: 36),
              const SizedBox(height: 10),
              Text(
                '${(_total / 1000).toStringAsFixed(2)} L',
                style: const TextStyle(
                    color: AppTheme.colorWater,
                    fontSize: 52,
                    fontWeight: FontWeight.w900),
              ),
              Text('von ${(_goal / 1000).toStringAsFixed(1)} L Tagesziel',
                  style: AppTheme.caption),
              const SizedBox(height: 14),
              NeonProgressBar(value: progress, color: AppTheme.colorWater, height: 10),
              const SizedBox(height: 8),
              Text(
                progress >= 1
                    ? '🎉 Tagesziel erreicht!'
                    : '${((_goal - _total) / 1000).toStringAsFixed(2)} L noch übrig',
                style: TextStyle(
                  color: progress >= 1 ? AppTheme.neonGreen : AppTheme.textSecondary,
                  fontWeight: progress >= 1 ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Schnell-Buttons
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Schnell hinzufügen', style: AppTheme.bodyBold),
              const SizedBox(height: 12),
              Row(children: _quick.map((ml) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _add(ml),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.colorWater.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                            color: AppTheme.colorWater.withOpacity(0.3)),
                      ),
                      child: Text('${ml}ml',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.colorWater,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                  ),
                ),
              )).toList()),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _customDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Eigene Menge'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.colorWater,
                    side: BorderSide(
                        color: AppTheme.colorWater.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Einträge
          if (_entries.isNotEmpty) ...[
            const Text('Heute', style: AppTheme.headline3),
            const SizedBox(height: 10),
            ..._entries.reversed.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.colorWater.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop,
                        color: AppTheme.colorWater, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.amountMl} ml', style: AppTheme.bodyBold),
                      Text(DateFormat('HH:mm').format(e.date),
                          style: AppTheme.caption),
                    ],
                  )),
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
