class UserModel {
  String id;
  String firstName;
  String lastName;
  String email;
  String phoneNo;
  String roleId;
  String? imageURL;
  String roleTitle;
  String token;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNo,
    required this.roleId,
    required this.imageURL,
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
        imgUrl = userMap['userProfile']['imageUrl'] ??
            userMap['userProfile']['imageURL'] ??
            userMap['userProfile']['image'] ??
            userMap['userProfile']['profileImage'];
      } else if (userMap['userProfile'] is String) {
        imgUrl = userMap['userProfile'];
      }
    }

    // fallback to top level or common keys
    imgUrl ??= userMap['imageUrl'] ??
        userMap['imageURL'] ??
        userMap['image'] ??
        userMap['imageurl'] ??
        userMap['profileImage'] ??
        userMap['photo'];

    // 3. Clean and process URL
    if (imgUrl != null &&
        imgUrl.toString().toLowerCase() != 'null' &&
        imgUrl.toString().trim().isNotEmpty) {
      imgUrl = imgUrl.toString().trim();

      // Only prepend base URL if it's not a full URL and not a local path
      if (!imgUrl.startsWith('http')) {
        bool isLocalPath = imgUrl.contains('/data/') ||
            imgUrl.contains('/var/') ||
            imgUrl.contains('/storage/') ||
            imgUrl.contains('/Users/');

        if (!isLocalPath) {
          if (!imgUrl.startsWith('/')) {
            imgUrl = "/$imgUrl";
          }
          imgUrl = "https://test.thefutureinno.com$imgUrl";
        }
      }

      // Add cache breaker if it's a network image
      if (imgUrl.startsWith('http')) {
        if (!imgUrl.contains('?t=')) {
          if (imgUrl.contains('?')) {
            imgUrl = "$imgUrl&t=${DateTime.now().millisecondsSinceEpoch}";
          } else {
            imgUrl = "$imgUrl?t=${DateTime.now().millisecondsSinceEpoch}";
          }
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
      imageURL: imgUrl,
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
      'imageUrl': imageURL, // Ensure direct access at root
      'imageURL': imageURL, // Also offer imageURL
      'userProfile': {'imageUrl': imageURL}, // Keep existing structure
      'role': {'title': roleTitle},
      'roleTitle': roleTitle,
      'token': token,
    };
  }
}
