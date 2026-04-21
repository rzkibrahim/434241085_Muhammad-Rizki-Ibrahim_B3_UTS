class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String password;
  final String role; // 'user', 'helpdesk', 'admin'
  final String department;
  final String avatar;
  final String phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.password,
    required this.role,
    required this.department,
    required this.avatar,
    required this.phone,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? department,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username,
      password: password,
      role: role,
      department: department ?? this.department,
      avatar: avatar,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'role': role,
      'department': department,
      'avatar': avatar,
      'phone': phone,
    };
  }
}
