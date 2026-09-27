class SavingsRecord {
  final int? id;
  final String month;
  final double income;
  final double targetAmount;
  final double savedAmount;
  final String createdAt;

  const SavingsRecord({
    this.id,
    required this.month,
    required this.income,
    required this.targetAmount,
    required this.savedAmount,
    required this.createdAt,
  });

  factory SavingsRecord.fromMap(Map<String, Object?> map) {
    return SavingsRecord(
      id: map['id'] as int?,
      month: map['month'] as String,
      income: (map['income'] as num).toDouble(),
      targetAmount: (map['targetAmount'] as num).toDouble(),
      savedAmount: (map['savedAmount'] as num).toDouble(),
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'month': month,
      'income': income,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'createdAt': createdAt,
    };
  }
}
