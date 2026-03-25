class VitalsEntry {
  final int? id;
  final int? systolic;    // mmHg
  final int? diastolic;   // mmHg
  final int? heartRate;   // bpm
  final int? spo2;        // %
  final double? temperature; // °C
  final String? notes;
  final DateTime date;

  VitalsEntry({
    this.id,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.spo2,
    this.temperature,
    this.notes,
    required this.date,
  });

  factory VitalsEntry.fromMap(Map<String, dynamic> m) => VitalsEntry(
    id: m['id'],
    systolic: m['systolic'],
    diastolic: m['diastolic'],
    heartRate: m['heart_rate'],
    spo2: m['spo2'],
    temperature: m['temperature'] != null
        ? (m['temperature'] as num).toDouble()
        : null,
    notes: m['notes'],
    date: DateTime.parse(m['date']),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'systolic': systolic,
    'diastolic': diastolic,
    'heart_rate': heartRate,
    'spo2': spo2,
    'temperature': temperature,
    'notes': notes,
    'date': date.toIso8601String(),
  };

  String get bpFormatted => (systolic != null && diastolic != null)
      ? '$systolic/$diastolic mmHg'
      : '—';

  String get bpCategory {
    if (systolic == null || diastolic == null) return '';
    if (systolic! < 120 && diastolic! < 80) return 'Optimal';
    if (systolic! < 130 && diastolic! < 85) return 'Normal';
    if (systolic! < 140 && diastolic! < 90) return 'Hochnormal';
    if (systolic! < 160 || diastolic! < 100) return 'Hypertonie Grad 1';
    return 'Hypertonie Grad 2';
  }

  String get hrCategory {
    if (heartRate == null) return '';
    if (heartRate! < 60) return 'Bradykardie';
    if (heartRate! <= 100) return 'Normal';
    return 'Tachykardie';
  }
}
