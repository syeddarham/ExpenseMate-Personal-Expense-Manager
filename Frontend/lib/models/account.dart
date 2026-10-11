class Account {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'card', 'wallet'
  final double openingBalance;
  final double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.balance,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Account',
      type: json['type'] as String? ?? 'cash',
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'opening_balance': openingBalance,
      'balance': balance,
    };
  }
}
