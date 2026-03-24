class WaterEntry {
  final int? id;
  final int amountMl;
  final DateTime date;

  WaterEntry({this.id, required this.amountMl, required this.date});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'amount_ml': amountMl,
        'date': date.toIso8601String(),
      };

  factory WaterEntry.fromMap(Map<String, dynamic> map) => WaterEntry(
        id: map['id'],
        amountMl: map['amount_ml'],
        date: DateTime.parse(map['date']),
      );
}
