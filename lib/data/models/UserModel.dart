class UserModel {
  String id;
  String firstName;
  String lastName;
  String email;
  String roleId;
  String? imageUrl;
  String roleTitle;
  String token;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roleId,
    required this.imageUrl,
    required this.roleTitle,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return UserModel(
      id: user['id'],
      firstName: user['firstName'],
      lastName: user['lastName'],
      email: user['email'],
      roleId: user['roleId'],
      imageUrl: user['userProfile']?['imageUrl'],
      roleTitle: user['role']?['title'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'roleId': roleId,
      'imageUrl': imageUrl,
      'roleTitle': roleTitle,
      'token': token,
    };
  }

  @override
  String toString() {
    return firstName;
  }
}
