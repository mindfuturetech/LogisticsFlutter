class User {
  String name;
  String profile;
  String password;
  String createdTime;
  String updatedTime;

  User({
    required this.name,
    required this.profile,
    required this.password,
    required this.createdTime,
    required this.updatedTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profile': profile,
      'password': password,
      'created_time': createdTime,
      'updated_time': updatedTime,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'],
      profile: map['profile'],
      password: map['password'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
    );
  }
}
