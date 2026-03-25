class MedicationEntry {
  final int? id;
  final String name;
  final String dosage;      // e.g. "10mg", "1 Tablette"
  final String frequency;   // "täglich", "2x täglich", "bei Bedarf"
  final String timeOfDay;   // "morgens", "mittags", "abends", "morgens + abends"
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  MedicationEntry({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timeOfDay,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  factory MedicationEntry.fromMap(Map<String, dynamic> m) => MedicationEntry(
    id: m['id'],
    name: m['name'],
    dosage: m['dosage'],
    frequency: m['frequency'],
    timeOfDay: m['time_of_day'],
    notes: m['notes'],
    isActive: (m['is_active'] as int) == 1,
    createdAt: DateTime.parse(m['created_at']),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'time_of_day': timeOfDay,
    'notes': notes,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };
}
