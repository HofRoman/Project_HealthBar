import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/medication_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _db = DatabaseHelper();
  List<MedicationEntry> _entries = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await _db.getMedications();
    setState(() => _entries = data.map(MedicationEntry.fromMap).toList());
  }

  Future<void> _showAddDialog([MedicationEntry? existing]) async {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final dosageCtrl =
        TextEditingController(text: existing?.dosage ?? '');
    final notesCtrl =
        TextEditingController(text: existing?.notes ?? '');
    String freq = existing?.frequency ?? 'täglich';
    String time = existing?.timeOfDay ?? 'morgens';

    final freqs = ['täglich', '2x täglich', '3x täglich', 'wöchentlich', 'bei Bedarf'];
    final times = ['morgens', 'mittags', 'abends', 'morgens + abends', 'morgens + mittags + abends', 'zu den Mahlzeiten'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLarge)),
          title: Text(
            existing == null ? 'Medikament hinzufügen' : 'Bearbeiten',
            style: AppTheme.headline3,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DlgField(ctrl: nameCtrl, label: 'Medikament / Wirkstoff',
                        hint: 'z.B. Ibuprofen, Vitamin D3',
                        icon: Icons.medication),
                    const SizedBox(height: 10),
                    _DlgField(ctrl: dosageCtrl, label: 'Dosierung',
                        hint: 'z.B. 400mg, 1 Tablette, 5ml',
                        icon: Icons.straighten),
                    const SizedBox(height: 14),
                    const Text('Häufigkeit', style: AppTheme.caption),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 6, children: freqs.map((f) {
                      final sel = freq == f;
                      return GestureDetector(
                        onTap: () => setDlg(() => freq = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.colorMeds.withOpacity(0.2)
                                : AppTheme.glassWhite,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.colorMeds.withOpacity(0.6)
                                  : AppTheme.glassBorder,
                            ),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                color: sel
                                    ? AppTheme.colorMeds
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              )),
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 14),
                    const Text('Einnahmezeit', style: AppTheme.caption),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 6, children: times.map((t) {
                      final sel = time == t;
                      return GestureDetector(
                        onTap: () => setDlg(() => time = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.neon.withOpacity(0.15)
                                : AppTheme.glassWhite,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.neon.withOpacity(0.5)
                                  : AppTheme.glassBorder,
                            ),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                color: sel
                                    ? AppTheme.neon
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              )),
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 12),
                    _DlgField(
                        ctrl: notesCtrl,
                        label: 'Notizen (optional)',
                        hint: 'z.B. nach dem Essen einnehmen',
                        icon: Icons.notes,
                        maxLines: 2),
                  ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen',
                    style: TextStyle(color: AppTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final dosage = dosageCtrl.text.trim();
                if (name.isNotEmpty && dosage.isNotEmpty) {
                  if (existing != null) {
                    _db.deleteMedication(existing.id!);
                  }
                  _db.insertMedication(MedicationEntry(
                    name: name,
                    dosage: dosage,
                    frequency: freq,
                    timeOfDay: time,
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  ).toMap());
                  _load();
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorMeds,
                  foregroundColor: Colors.white),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeIcon(String time) {
    if (time.contains('morgens') && time.contains('abends') && time.contains('mittags')) {
      return const Text('☀️🌤️🌙');
    }
    if (time.contains('morgens') && time.contains('abends')) return const Text('☀️🌙');
    if (time.contains('morgens')) return const Text('☀️');
    if (time.contains('mittags')) return const Text('🌤️');
    if (time.contains('abends')) return const Text('🌙');
    if (time.contains('Mahlzeit')) return const Text('🍽️');
    return const Text('💊');
  }

  @override
  Widget build(BuildContext context) {
    final active = _entries.where((e) => e.isActive).toList();
    final inactive = _entries.where((e) => !e.isActive).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.colorMeds.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medication,
                color: AppTheme.colorMeds, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Medikamente'),
        ]),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_circle_outline,
                color: AppTheme.colorMeds),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.colorMeds,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _entries.isEmpty
          ? _emptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Info Banner
                  GlassCard(
                    glowColor: AppTheme.colorMeds,
                    glowIntensity: 0.12,
                    child: Row(children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.colorMeds, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${active.length} aktive${inactive.isNotEmpty ? ', ${inactive.length} pausiert' : ''} · Tippe auf Ein/Aus zum umschalten',
                          style: AppTheme.caption,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  if (active.isNotEmpty) ...[
                    const Text('Aktiv', style: AppTheme.headline3),
                    const SizedBox(height: 10),
                    ...active.map((e) => _MedCard(
                      entry: e,
                      timeIcon: _timeIcon(e.timeOfDay),
                      onToggle: () async {
                        await _db.updateMedicationActive(e.id!, !e.isActive);
                        _load();
                      },
                      onEdit: () => _showAddDialog(e),
                      onDelete: () async {
                        await _db.deleteMedication(e.id!);
                        _load();
                      },
                    )),
                    const SizedBox(height: 16),
                  ],

                  if (inactive.isNotEmpty) ...[
                    const Text('Pausiert', style: AppTheme.headline3),
                    const SizedBox(height: 10),
                    ...inactive.map((e) => _MedCard(
                      entry: e,
                      timeIcon: _timeIcon(e.timeOfDay),
                      onToggle: () async {
                        await _db.updateMedicationActive(e.id!, !e.isActive);
                        _load();
                      },
                      onEdit: () => _showAddDialog(e),
                      onDelete: () async {
                        await _db.deleteMedication(e.id!);
                        _load();
                      },
                    )),
                  ],
                ]),
            ),
    );
  }

  Widget _emptyState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: AppTheme.colorMeds.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.colorMeds.withOpacity(0.3), width: 2),
          ),
          child: const Icon(Icons.medication_outlined,
              size: 48, color: AppTheme.colorMeds),
        ),
        const SizedBox(height: 20),
        const Text('Keine Medikamente', style: AppTheme.headline3),
        const SizedBox(height: 8),
        const Text(
          'Füge deine Medikamente hinzu, um nie eine Einnahme zu verpassen.',
          style: AppTheme.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Erstes Medikament hinzufügen'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorMeds,
              foregroundColor: Colors.white),
        ),
      ]),
    ));
  }
}

class _MedCard extends StatelessWidget {
  final MedicationEntry entry;
  final Widget timeIcon;
  final VoidCallback onToggle, onEdit, onDelete;

  const _MedCard({
    required this.entry,
    required this.timeIcon,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        glowColor: entry.isActive ? AppTheme.colorMeds : AppTheme.textMuted,
        glowIntensity: entry.isActive ? 0.12 : 0.03,
        child: Opacity(
          opacity: entry.isActive ? 1.0 : 0.6,
          child: Row(children: [
            // Icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.colorMeds.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  timeIcon,
                  const SizedBox(height: 2),
                  const Icon(Icons.medication,
                      color: AppTheme.colorMeds, size: 14),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: AppTheme.bodyBold),
                const SizedBox(height: 2),
                Row(children: [
                  NeonBadge(entry.dosage, color: AppTheme.colorMeds),
                  const SizedBox(width: 6),
                  NeonBadge(entry.frequency, color: AppTheme.neon),
                ]),
                const SizedBox(height: 2),
                Text(entry.timeOfDay, style: AppTheme.caption),
                if (entry.notes != null)
                  Text(entry.notes!, style: AppTheme.caption),
              ],
            )),
            Column(children: [
              // Toggle
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.isActive
                        ? AppTheme.neonGreen.withOpacity(0.15)
                        : AppTheme.textMuted.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    entry.isActive ? 'AN' : 'AUS',
                    style: TextStyle(
                      color: entry.isActive
                          ? AppTheme.neonGreen
                          : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: AppTheme.colorFood),
                ),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _DlgField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final int maxLines;
  const _DlgField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.colorMeds, size: 18),
      ),
    );
  }
}
