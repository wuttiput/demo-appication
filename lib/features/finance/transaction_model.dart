class TransactionModel {
  final int? id;
  final int userId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String? description;
  final String date; // YYYY-MM-DD

  TransactionModel({
    this.id,
    this.userId = 1,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
  });

  // Convert to Map for Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date,
    };
  }

  // Create from SQLite Row
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      amount: map['amount'] as double,
      description: map['description'] as String?,
      date: map['date'] as String,
    );
  }
}
