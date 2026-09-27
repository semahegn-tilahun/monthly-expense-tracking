class AppUser {
  final int? id;
  final String name;
  final String email;
  final String pin;
  final String createdAt;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.pin,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      pin: map['pin'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'pin': pin,
      'createdAt': createdAt,
    };
  }
}
