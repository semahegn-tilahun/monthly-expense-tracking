class ExpenseCategory {
  final int? id;
  final String name;
  final String type;
  final double monthlyBudget;

  const ExpenseCategory({
    this.id,
    required this.name,
    required this.type,
    required this.monthlyBudget,
  });

  factory ExpenseCategory.fromMap(Map<String, Object?> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      monthlyBudget: (map['monthlyBudget'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'monthlyBudget': monthlyBudget,
    };
  }

  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? type,
    double? monthlyBudget,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}
