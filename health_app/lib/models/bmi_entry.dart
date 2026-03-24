class BmiEntry {
  final int? id;
  final double weight; // kg
  final double height; // cm
  final double bmi;
  final DateTime date;

  BmiEntry({
    this.id,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.date,
  });

  String get category {
    if (bmi < 18.5) return 'Untergewicht';
    if (bmi < 25.0) return 'Normalgewicht';
    if (bmi < 30.0) return 'Übergewicht';
    return 'Adipositas';
  }

  String get categoryEmoji {
    if (bmi < 18.5) return '⚠️';
    if (bmi < 25.0) return '✅';
    if (bmi < 30.0) return '⚠️';
    return '🔴';
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'date': date.toIso8601String(),
      };

  factory BmiEntry.fromMap(Map<String, dynamic> map) => BmiEntry(
        id: map['id'],
        weight: map['weight'],
        height: map['height'],
        bmi: map['bmi'],
        date: DateTime.parse(map['date']),
      );

  static double calculate(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
}
