class CreditPayment {
  final int? id;
  final String lender;
  final String paymentMonth;
  final double paymentAmount;
  final double totalDebtBefore;
  final double totalDebtAfter;
  final String paidAt;
  final String note;

  const CreditPayment({
    this.id,
    required this.lender,
    required this.paymentMonth,
    required this.paymentAmount,
    required this.totalDebtBefore,
    required this.totalDebtAfter,
    required this.paidAt,
    required this.note,
  });

  factory CreditPayment.fromMap(Map<String, Object?> map) {
    return CreditPayment(
      id: map['id'] as int?,
      lender: map['lender'] as String,
      paymentMonth: map['paymentMonth'] as String,
      paymentAmount: (map['paymentAmount'] as num).toDouble(),
      totalDebtBefore: (map['totalDebtBefore'] as num).toDouble(),
      totalDebtAfter: (map['totalDebtAfter'] as num).toDouble(),
      paidAt: map['paidAt'] as String,
      note: (map['note'] ?? '') as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'lender': lender,
      'paymentMonth': paymentMonth,
      'paymentAmount': paymentAmount,
      'totalDebtBefore': totalDebtBefore,
      'totalDebtAfter': totalDebtAfter,
      'paidAt': paidAt,
      'note': note,
    };
  }
}
