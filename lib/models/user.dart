class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String preferredCurrency;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.preferredCurrency = 'USD',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      preferredCurrency: json['preferred_currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'preferred_currency': preferredCurrency,
    };
  }
}
