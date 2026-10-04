import 'package:flutter/material.dart';

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isExpense = true,
  });

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(json['icon_code'] as int? ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(json['color_value'] as int? ?? 0xFF10B981),
      isExpense: json['is_expense'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_code': icon.codePoint,
      'color_value': color.toARGB32(),
      'is_expense': isExpense,
    };
  }

  static const List<TransactionCategory> defaultCategories = [
    TransactionCategory(id: 'food', name: 'Food & Dining', icon: Icons.restaurant, color: Color(0xFFF59E0B)),
    TransactionCategory(id: 'groceries', name: 'Groceries', icon: Icons.shopping_cart, color: Color(0xFF10B981)),
    TransactionCategory(id: 'transport', name: 'Transport', icon: Icons.directions_car, color: Color(0xFF3B82F6)),
    TransactionCategory(id: 'bills', name: 'Bills & Utilities', icon: Icons.receipt_long, color: Color(0xFF8B5CF6)),
    TransactionCategory(id: 'entertainment', name: 'Entertainment', icon: Icons.movie, color: Color(0xFFEC4899)),
    TransactionCategory(id: 'health', name: 'Health', icon: Icons.medical_services, color: Color(0xFFEF4444)),
    TransactionCategory(id: 'salary', name: 'Salary / Income', icon: Icons.attach_money, color: Color(0xFF059669), isExpense: false),
    TransactionCategory(id: 'investments', name: 'Investments', icon: Icons.trending_up, color: Color(0xFF06B6D4), isExpense: false),
  ];
}
