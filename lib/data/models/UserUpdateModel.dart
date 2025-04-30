class UserUpdateResponse {
  final String message;
  final UserUpdateData data;

  UserUpdateResponse({
    required this.message,
    required this.data,
  });

  factory UserUpdateResponse.fromJson(Map<String, dynamic> json) {
    return UserUpdateResponse(
      message: json['message'],
      data: UserUpdateData.fromJson(json['data']),
    );
  }
}

class UserUpdateData {
  final String id;
  final String title;
  final String firstName;
  final String lastName;
  final String email;
  final String roleId;
  final String phoneNo;
  final UserProfile userProfile;
  final UserRole role;

  UserUpdateData({
    required this.id,
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roleId,
    required this.phoneNo,
    required this.userProfile,
    required this.role,
  });

  factory UserUpdateData.fromJson(Map<String, dynamic> json) {
    return UserUpdateData(
      id: json['id'],
      title: json['title'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      roleId: json['roleId'],
      phoneNo: json['phoneNo'],
      userProfile: UserProfile.fromJson(json['userProfile']),
      role: UserRole.fromJson(json['role']),
    );
  }
}

class UserProfile {
  final String id;
  final String? imageUrl;

  UserProfile({
    required this.id,
    required this.imageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      imageUrl: json['imageUrl'],
    );
  }
}

class UserRole {
  final String title;

  UserRole({
    required this.title,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      title: json['title'],
    );
  }
}