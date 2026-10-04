class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String preferredCurrency;
  final String? currencySymbol;
  final String? country;
  final bool emailVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.preferredCurrency = 'USD',
    this.currencySymbol = '\$',
    this.country,
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      preferredCurrency: json['preferred_currency'] as String? ?? json['currency_code'] as String? ?? 'USD',
      currencySymbol: json['currency_symbol'] as String? ?? '\$',
      country: json['country'] as String?,
      emailVerified: json['email_verified'] is bool
          ? (json['email_verified'] as bool)
          : (json['email_verified'] == 1 || json['email_verified'] == '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'preferred_currency': preferredCurrency,
      'currency_symbol': currencySymbol,
      'country': country,
      'email_verified': emailVerified,
    };
  }
}
