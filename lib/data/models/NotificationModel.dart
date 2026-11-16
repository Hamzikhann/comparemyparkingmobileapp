// notification_model.dart
class User {
  final String id;
  final List<Booking> bookings;

  User({
    required this.id,
    required this.bookings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var bookingsList = json['bookings'] as List? ?? [];
    List<Booking> bookings = bookingsList
        .map((booking) => Booking.fromJson(booking))
        .toList();

    return User(
      id: json['id'] ?? '',
      bookings: bookings,
    );
  }
}

class Booking {
  final String id;

  Booking({
    required this.id,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String? body;
  final bool isRead;
  final String? type;
  final String isActive;
  final String createdAt;
  final String updatedAt;
  final String userId;
  final User? user;

  /// Job notifications: encrypted id of the booking they are about.
  final String bookingId;

  NotificationModel({
    required this.id,
    required this.title,
    this.body,
    required this.isRead,
    this.type,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.user,
    this.bookingId = '',
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'],
      isRead: json['isRead'] ?? false,
      type: json['type'],
      isActive: json['isActive'] ?? 'N',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      userId: json['userId'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      bookingId: (json['bookingId'] ?? '').toString(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    String? type,
    String? isActive,
    String? createdAt,
    String? updatedAt,
    String? userId,
    User? user,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      bookingId: bookingId,
    );
  }
}

class NotificationResponse {
  final String message;
  final List<NotificationModel> notifications;

  NotificationResponse({
    required this.message,
    required this.notifications,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    var notificationsList = json['data'] as List? ?? [];
    List<NotificationModel> notifications = notificationsList
        .map((notification) => NotificationModel.fromJson(notification))
        .toList();

    return NotificationResponse(
      message: json['message'] ?? '',
      notifications: notifications,
    );
  }
}