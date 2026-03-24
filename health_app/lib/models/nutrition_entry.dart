class NutritionEntry {
  final int? id;
  final String mealName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime date;

  NutritionEntry({
    this.id,
    required this.mealName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'meal_name': mealName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'date': date.toIso8601String(),
      };

  factory NutritionEntry.fromMap(Map<String, dynamic> map) => NutritionEntry(
        id: map['id'],
        mealName: map['meal_name'],
        calories: map['calories'],
        protein: map['protein'] ?? 0.0,
        carbs: map['carbs'] ?? 0.0,
        fat: map['fat'] ?? 0.0,
        date: DateTime.parse(map['date']),
      );
}
