class SleepEntry {
  final int? id;
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final double durationHours;
  final int quality; // 1-5
  final DateTime date;

  SleepEntry({
    this.id,
    required this.sleepStart,
    required this.sleepEnd,
    required this.durationHours,
    required this.quality,
    required this.date,
  });

  String get qualityLabel {
    switch (quality) {
      case 1: return 'Sehr schlecht';
      case 2: return 'Schlecht';
      case 3: return 'Okay';
      case 4: return 'Gut';
      case 5: return 'Ausgezeichnet';
      default: return 'Unbekannt';
    }
  }

  String get qualityEmoji {
    switch (quality) {
      case 1: return '😴';
      case 2: return '😪';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😊';
      default: return '💤';
    }
  }

  String get durationFormatted {
    final h = durationHours.floor();
    final m = ((durationHours - h) * 60).round();
    return '${h}h ${m}min';
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'sleep_start': sleepStart.toIso8601String(),
        'sleep_end': sleepEnd.toIso8601String(),
        'duration_hours': durationHours,
        'quality': quality,
        'date': date.toIso8601String(),
      };

  factory SleepEntry.fromMap(Map<String, dynamic> map) => SleepEntry(
        id: map['id'],
        sleepStart: DateTime.parse(map['sleep_start']),
        sleepEnd: DateTime.parse(map['sleep_end']),
        durationHours: map['duration_hours'],
        quality: map['quality'],
        date: DateTime.parse(map['date']),
      );
}
