class User {
  final int id;
  final String name;
  final String cpf;
  final String school;
  final String registration;
  final double balance;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.cpf,
    required this.school,
    required this.registration,
    required this.balance,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      cpf: json['cpf'] as String,
      school: json['school'] as String,
      registration: json['registration'] as String,
      balance: (json['balance'] as num).toDouble(),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cpf': cpf,
    'school': school,
    'registration': registration,
    'balance': balance,
    'avatar_url': avatarUrl,
  };
}
