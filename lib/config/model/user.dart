class User {
  final String username;
  final String profile;

  User({
    required this.username,
    required this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      profile: json['profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'profile': profile,
    };
  }
}