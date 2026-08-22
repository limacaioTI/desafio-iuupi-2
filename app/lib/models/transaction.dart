enum TransactionType { credit, debit }

TransactionType transactionTypeFromString(String value) {
  return value == 'credit' ? TransactionType.credit : TransactionType.debit;
}

class Transaction {
  final int id;
  final TransactionType type;
  final String description;
  final double amount;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      type: transactionTypeFromString(json['type'] as String),
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == TransactionType.credit ? 'credit' : 'debit',
    'description': description,
    'amount': amount,
    'created_at': createdAt.toIso8601String(),
  };
}
