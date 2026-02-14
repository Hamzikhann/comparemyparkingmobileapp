class UserModel {
  String id;
  String firstName;
  String lastName;
  String email;
  String phoneNo;
  String roleId;
  String? imageUrl;
  String roleTitle;
  String token;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNo,
    required this.roleId,
    required this.imageUrl,
    required this.roleTitle,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Identify the user data map (handle wrapped or unwrapped)
    final userMap =
        (json['user'] != null && json['user'] is Map) ? json['user'] : json;

    // 2. Extract imageUrl robustly
    String? imgUrl;
    if (userMap['userProfile'] != null) {
      if (userMap['userProfile'] is Map) {
        imgUrl = userMap['userProfile']['imageUrl'];
      } else if (userMap['userProfile'] is String) {
        imgUrl = userMap['userProfile'];
      }
    }
    imgUrl ??= userMap['imageUrl'];

    // 3. Clean and process URL
    if (imgUrl != null &&
        imgUrl.toString().toLowerCase() != 'null' &&
        imgUrl.toString().trim().isNotEmpty) {
      imgUrl = imgUrl.toString().trim();
      // Only prepend http if it DOES NOT look like a local path
      // Local paths usually start with /data/ (Android) or /var/ (iOS) or /storage/
      // Relative API paths usually start with /uploads/ or /images/ or similar
      if (!imgUrl.startsWith('http')) {
        // If it looks like a local absolute path, keep it as is
        // Simple heuristic: if it contains typical local path segments
        bool isLocalPath = imgUrl.contains('/data/') ||
            imgUrl.contains('/var/') ||
            imgUrl.contains('/storage/') ||
            imgUrl.contains('/Users/'); // iOS/Simulators

        if (!isLocalPath) {
          if (!imgUrl.startsWith('/')) {
            imgUrl = "/$imgUrl";
          }
          imgUrl = "https://test.thefutureinno.com$imgUrl";
        }
      }
    } else {
      imgUrl = null;
    }

    return UserModel(
      id: userMap['id']?.toString() ?? '',
      firstName: userMap['firstName']?.toString() ?? '',
      lastName: userMap['lastName']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      phoneNo: userMap['phoneNo']?.toString() ?? '',
      roleId: userMap['roleId']?.toString() ?? '',
      imageUrl: imgUrl,
      roleTitle: userMap['role'] is Map
          ? (userMap['role']['title']?.toString() ?? '')
          : (userMap['roleTitle']?.toString() ?? ''),
      token: (json['token'] ?? userMap['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNo': phoneNo,
      'roleId': roleId,
      'imageUrl': imageUrl, // Ensure direct access at root
      'userProfile': {'imageUrl': imageUrl}, // Keep existing structure
      'role': {'title': roleTitle},
      'roleTitle': roleTitle,
      'token': token,
    };
  }
}
