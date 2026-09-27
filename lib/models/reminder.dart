class ReminderRecord {
  final int? id;
  final String title;
  final String message;
  final String remindAt;
  final bool isDone;
  final String createdAt;

  const ReminderRecord({
    this.id,
    required this.title,
    required this.message,
    required this.remindAt,
    required this.isDone,
    required this.createdAt,
  });

  bool get isDue {
    final parsed = DateTime.tryParse(remindAt);
    if (parsed == null) return false;
    return !isDone && !parsed.isAfter(DateTime.now());
  }

  factory ReminderRecord.fromMap(Map<String, Object?> map) {
    return ReminderRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      message: (map['message'] ?? '') as String,
      remindAt: map['remindAt'] as String,
      isDone: (map['isDone'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'remindAt': remindAt,
      'isDone': isDone ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  ReminderRecord copyWith({
    int? id,
    String? title,
    String? message,
    String? remindAt,
    bool? isDone,
    String? createdAt,
  }) {
    return ReminderRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      remindAt: remindAt ?? this.remindAt,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
