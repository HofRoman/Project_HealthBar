import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/water_entry.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _db = DatabaseHelper();
  List<WaterEntry> _todayEntries = [];
  int _totalMl = 0;
  final int _goalMl = 2500;

  final List<int> _quickAmounts = [150, 200, 300, 500];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _db.getWaterToday();
    final entries = data.map(WaterEntry.fromMap).toList();
    setState(() {
      _todayEntries = entries;
      _totalMl = entries.fold(0, (s, e) => s + e.amountMl);
    });
  }

  Future<void> _addWater(int ml) async {
    await _db.insertWater(WaterEntry(
      amountMl: ml,
      date: DateTime.now(),
    ).toMap());
    _load();
  }

  Future<void> _deleteEntry(int id) async {
    await _db.deleteWaterEntry(id);
    _load();
  }

  Future<void> _showCustomDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Menge eingeben'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Menge in ml',
            hintText: 'z.B. 250',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(controller.text);
              if (ml != null && ml > 0) {
                _addWater(ml);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3)),
            child: const Text('Hinzufügen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  double get _progress => (_totalMl / _goalMl).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Wassertracker'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hauptanzeige
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop,
                        color: Color(0xFF2196F3), size: 40),
                    const SizedBox(height: 12),
                    Text(
                      '${(_totalMl / 1000).toStringAsFixed(2)} L',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    Text(
                      'von ${(_goalMl / 1000).toStringAsFixed(1)} L Tagesziel',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor:
                            const Color(0xFF2196F3).withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3)),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _progress >= 1.0
                          ? 'Tagesziel erreicht!'
                          : '${((_goalMl - _totalMl) / 1000).toStringAsFixed(2)} L noch übrig',
                      style: TextStyle(
                        color: _progress >= 1.0
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[500],
                        fontSize: 13,
                        fontWeight: _progress >= 1.0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Schnell-Buttons
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schnell hinzufügen',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ..._quickAmounts.map((ml) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: ElevatedButton(
                                  onPressed: () => _addWater(ml),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3)
                                        .withOpacity(0.1),
                                    foregroundColor:
                                        const Color(0xFF2196F3),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: Text('${ml}ml',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showCustomDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Eigene Menge'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2196F3),
                          side: const BorderSide(
                              color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Einträge heute
            if (_todayEntries.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Heute',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ..._todayEntries.reversed.map((e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.water_drop,
                            color: Color(0xFF2196F3)),
                      ),
                      title: Text('${e.amountMl} ml',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        DateFormat('HH:mm').format(e.date),
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deleteEntry(e.id!),
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
