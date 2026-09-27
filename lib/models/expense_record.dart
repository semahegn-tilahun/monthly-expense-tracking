class ExpenseRecord {
  final int? id;
  final int categoryId;
  final String categoryName;
  final String categoryType;
  final String title;
  final double amount;
  final String date;
  final String note;

  const ExpenseRecord({
    this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.title,
    required this.amount,
    required this.date,
    required this.note,
  });

  factory ExpenseRecord.fromMap(Map<String, Object?> map) {
    return ExpenseRecord(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      categoryName: (map['categoryName'] ?? '') as String,
      categoryType: (map['categoryType'] ?? '') as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      note: (map['note'] ?? '') as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'amount': amount,
      'date': date,
      'note': note,
    };
  }
}
