class WeeklyTrack {
  final int? id;
  final String weekLabel;
  final double plannedSpending;
  final double actualSpending;

  const WeeklyTrack({
    this.id,
    required this.weekLabel,
    required this.plannedSpending,
    required this.actualSpending,
  });

  double get difference => plannedSpending - actualSpending;

  factory WeeklyTrack.fromMap(Map<String, Object?> map) {
    return WeeklyTrack(
      id: map['id'] as int?,
      weekLabel: map['weekLabel'] as String,
      plannedSpending: (map['plannedSpending'] as num).toDouble(),
      actualSpending: (map['actualSpending'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'weekLabel': weekLabel,
      'plannedSpending': plannedSpending,
      'actualSpending': actualSpending,
    };
  }
}
