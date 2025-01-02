class UserProfile {
  final String id;
  String fullName;
  String email;
  String? avatar;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      if (avatar != null) 'avatar': avatar,
    };
  }
}
