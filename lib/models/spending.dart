class Spending {
  final int spendingId;
  final int userId;
  final String category;
  final int amount;
  final String? memo;
  final String date;
  final String? createdAt;

  Spending({
    required this.spendingId,
    required this.userId,
    required this.category,
    required this.amount,
    this.memo,
    required this.date,
    this.createdAt,
  });

  factory Spending.fromJson(Map<String, dynamic> json) {
    return Spending(
      spendingId: json['spending_id'],
      userId: json['user_id'],
      category: json['category'],
      amount: json['amount'],
      memo: json['memo'],
      date: json['date'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spending_id': spendingId,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'memo': memo,
      'date': date,
      'created_at': createdAt,
    };
  }
}
