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
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Category',
      icon: _parseIcon(json['icon'] ?? json['icon_code']),
      color: _parseColor(json['color'] ?? json['color_value']),
      isExpense: json['is_expense'] is bool
          ? (json['is_expense'] as bool)
          : (json['is_expense'] == 1 || json['is_expense'] == '1'),
    );
  }

  static IconData _parseIcon(dynamic raw) {
    if (raw is int) {
      return IconData(raw, fontFamily: 'MaterialIcons');
    }
    if (raw is String) {
      switch (raw.toLowerCase()) {
        case 'restaurant':
        case 'food':
          return Icons.restaurant;
        case 'shopping_cart':
        case 'groceries':
          return Icons.shopping_cart;
        case 'directions_car':
        case 'transport':
          return Icons.directions_car;
        case 'receipt_long':
        case 'bills':
          return Icons.receipt_long;
        case 'movie':
        case 'entertainment':
          return Icons.movie;
        case 'medical_services':
        case 'health':
          return Icons.medical_services;
        case 'shopping_bag':
        case 'shopping':
          return Icons.shopping_bag;
        case 'school':
        case 'education':
          return Icons.school;
        case 'flight':
        case 'travel':
          return Icons.flight;
        case 'pets':
          return Icons.pets;
        case 'fitness_center':
          return Icons.fitness_center;
        case 'sports_esports':
        case 'gaming':
          return Icons.sports_esports;
        case 'coffee':
        case 'cafe':
          return Icons.coffee;
        case 'local_gas_station':
        case 'fuel':
          return Icons.local_gas_station;
        case 'home':
        case 'housing':
          return Icons.home;
        case 'phone_android':
        case 'phone':
          return Icons.phone_android;
        case 'wifi':
        case 'internet':
          return Icons.wifi;
        case 'attach_money':
        case 'salary':
          return Icons.attach_money;
        case 'trending_up':
        case 'investments':
          return Icons.trending_up;
        case 'work':
        case 'freelance':
          return Icons.work;
        case 'card_giftcard':
        case 'gifts':
          return Icons.card_giftcard;
        default:
          return Icons.category;
      }
    }
    return Icons.category;
  }

  static Color _parseColor(dynamic raw) {
    if (raw is int) {
      return Color(raw);
    }
    if (raw is String && raw.isNotEmpty) {
      final hex = raw.replaceAll('#', '').trim();
      if (hex.length == 6) {
        final val = int.tryParse('FF$hex', radix: 16);
        if (val != null) return Color(val);
      } else if (hex.length == 8) {
        final val = int.tryParse(hex, radix: 16);
        if (val != null) return Color(val);
      }
    }
    return const Color(0xFF10B981);
  }

  static IconData parseIconName(String name) => _parseIcon(name);
  static Color parseColorHex(String hex) => _parseColor(hex);

  String get iconName {
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.shopping_cart) return 'shopping_cart';
    if (icon == Icons.directions_car) return 'directions_car';
    if (icon == Icons.receipt_long) return 'receipt_long';
    if (icon == Icons.movie) return 'movie';
    if (icon == Icons.medical_services) return 'medical_services';
    if (icon == Icons.shopping_bag) return 'shopping_bag';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.flight) return 'flight';
    if (icon == Icons.pets) return 'pets';
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.sports_esports) return 'sports_esports';
    if (icon == Icons.coffee) return 'coffee';
    if (icon == Icons.local_gas_station) return 'local_gas_station';
    if (icon == Icons.home) return 'home';
    if (icon == Icons.phone_android) return 'phone_android';
    if (icon == Icons.wifi) return 'wifi';
    if (icon == Icons.attach_money) return 'attach_money';
    if (icon == Icons.trending_up) return 'trending_up';
    if (icon == Icons.work) return 'work';
    if (icon == Icons.card_giftcard) return 'card_giftcard';
    return 'category';
  }

  String get colorHex {
    final r = ((color.r * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': iconName,
      'color': colorHex,
      'is_expense': isExpense,
    };
  }

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Food'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'Groceries'},
    {'name': 'directions_car', 'icon': Icons.directions_car, 'label': 'Transport'},
    {'name': 'receipt_long', 'icon': Icons.receipt_long, 'label': 'Bills'},
    {'name': 'movie', 'icon': Icons.movie, 'label': 'Movies'},
    {'name': 'medical_services', 'icon': Icons.medical_services, 'label': 'Health'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag, 'label': 'Shopping'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Education'},
    {'name': 'flight', 'icon': Icons.flight, 'label': 'Travel'},
    {'name': 'pets', 'icon': Icons.pets, 'label': 'Pets'},
    {'name': 'fitness_center', 'icon': Icons.fitness_center, 'label': 'Fitness'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports, 'label': 'Gaming'},
    {'name': 'coffee', 'icon': Icons.coffee, 'label': 'Cafe'},
    {'name': 'local_gas_station', 'icon': Icons.local_gas_station, 'label': 'Fuel'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Housing'},
    {'name': 'phone_android', 'icon': Icons.phone_android, 'label': 'Phone'},
    {'name': 'wifi', 'icon': Icons.wifi, 'label': 'Internet'},
    {'name': 'attach_money', 'icon': Icons.attach_money, 'label': 'Salary'},
    {'name': 'trending_up', 'icon': Icons.trending_up, 'label': 'Invest'},
    {'name': 'work', 'icon': Icons.work, 'label': 'Work'},
    {'name': 'card_giftcard', 'icon': Icons.card_giftcard, 'label': 'Gifts'},
  ];

  static const List<Color> availableColors = [
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFF0EA5E9), // Light Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFF059669), // Dark Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFFD946EF), // Fuchsia
    Color(0xFF84CC16), // Lime
  ];

  static const List<TransactionCategory> defaultCategories = [
    TransactionCategory(id: '1', name: 'Food & Dining', icon: Icons.restaurant, color: Color(0xFFF59E0B)),
    TransactionCategory(id: '2', name: 'Groceries', icon: Icons.shopping_cart, color: Color(0xFF10B981)),
    TransactionCategory(id: '3', name: 'Transport', icon: Icons.directions_car, color: Color(0xFF3B82F6)),
    TransactionCategory(id: '4', name: 'Bills & Utilities', icon: Icons.receipt_long, color: Color(0xFF8B5CF6)),
    TransactionCategory(id: '5', name: 'Entertainment', icon: Icons.movie, color: Color(0xFFEC4899)),
    TransactionCategory(id: '6', name: 'Health', icon: Icons.medical_services, color: Color(0xFFEF4444)),
    TransactionCategory(id: '7', name: 'Shopping', icon: Icons.shopping_bag, color: Color(0xFFF97316)),
    TransactionCategory(id: '8', name: 'Education', icon: Icons.school, color: Color(0xFF0EA5E9)),
    TransactionCategory(id: '9', name: 'Travel', icon: Icons.flight, color: Color(0xFF14B8A6)),
    TransactionCategory(id: '10', name: 'Salary / Income', icon: Icons.attach_money, color: Color(0xFF059669), isExpense: false),
    TransactionCategory(id: '11', name: 'Freelance', icon: Icons.work, color: Color(0xFF6366F1), isExpense: false),
    TransactionCategory(id: '12', name: 'Investments', icon: Icons.trending_up, color: Color(0xFF06B6D4), isExpense: false),
    TransactionCategory(id: '13', name: 'Gifts', icon: Icons.card_giftcard, color: Color(0xFFD946EF), isExpense: false),
  ];
}
