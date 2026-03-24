class ActivityEntry {
  final int? id;
  final String activityType;
  final int durationMinutes;
  final int caloriesBurned;
  final int steps;
  final DateTime date;

  ActivityEntry({
    this.id,
    required this.activityType,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.steps = 0,
    required this.date,
  });

  String get icon {
    switch (activityType.toLowerCase()) {
      case 'laufen':
        return '🏃';
      case 'radfahren':
        return '🚴';
      case 'schwimmen':
        return '🏊';
      case 'yoga':
        return '🧘';
      case 'krafttraining':
        return '💪';
      case 'wandern':
        return '🥾';
      default:
        return '🏋️';
    }
  }

  static const List<String> activityTypes = [
    'Laufen',
    'Radfahren',
    'Schwimmen',
    'Yoga',
    'Krafttraining',
    'Wandern',
    'Spaziergang',
    'Tanzen',
    'Fußball',
    'Tennis',
  ];

  // Geschätzte Kalorien pro Minute (MET-Werte approximiert)
  static int estimateCalories(String type, int minutes, double weightKg) {
    const met = {
      'laufen': 9.8,
      'radfahren': 7.5,
      'schwimmen': 8.0,
      'yoga': 2.5,
      'krafttraining': 5.0,
      'wandern': 5.3,
      'spaziergang': 3.5,
      'tanzen': 5.0,
      'fußball': 7.0,
      'tennis': 7.3,
    };
    final metValue = met[type.toLowerCase()] ?? 4.0;
    return ((metValue * weightKg * minutes) / 60).round();
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'activity_type': activityType,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
        'steps': steps,
        'date': date.toIso8601String(),
      };

  factory ActivityEntry.fromMap(Map<String, dynamic> map) => ActivityEntry(
        id: map['id'],
        activityType: map['activity_type'],
        durationMinutes: map['duration_minutes'],
        caloriesBurned: map['calories_burned'],
        steps: map['steps'] ?? 0,
        date: DateTime.parse(map['date']),
      );
}
