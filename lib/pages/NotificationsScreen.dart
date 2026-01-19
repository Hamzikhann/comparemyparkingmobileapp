import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/GlobalsBookingDetail.dart';
import 'package:parkingapp/data/models/NotificationModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/ViewallScreen.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GeneralRepository _repository = GeneralRepository();
  List<NotificationModel> _notifications = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _errorMessage = '';
    });

    try {
      final response = await _repository.getNotifications();
      setState(() {
        _notifications = response.notifications;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    if (_notifications.isEmpty) return;

    try {
      EasyLoading.show(status: "Clearing notifications...");
      final notificationIds = _notifications.map((n) => n.id).toList();
      final message = await _repository.clearAllNotifications(notificationIds);

      setState(() {
        _notifications.clear();
      });

      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear notifications: $e')),
      );
    }
  }

  Future<void> _markAsReadAndNavigate(
      String notificationId, List<String> bookingIds) async {
    try {
      await _repository.markNotificationsAsRead([notificationId]);

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });

      final allBookings = [
        ...GlobalsBookingDetail.reservedParkings,
      ];

      final relevantBookings = allBookings.where((parking) {
        return bookingIds.contains(parking.id) ||
            parking.registrations
                .any((reg) => bookingIds.contains(reg.bookingId));
      }).toList();

      if (relevantBookings.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ViewAllScreen(title: "Reserved", parkings: relevantBookings),
          ),
        );
      } else {}
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error: $e')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              greeting: 'Notifications',
              showBackButton: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            if (_notifications.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _clearAllNotifications,
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading notifications',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            CustomButton(
              text: "Retry",
              onPressed: _loadNotifications,
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications',
          style: TextStyle(
            color: colors.textFieldBorder,
            fontSize: 16.sp,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final dateTime =
        DateTime.tryParse(notification.createdAt) ?? DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
    final bookingIds =
        notification.user?.bookings.map((b) => b.id).toList() ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: notification.isRead ? Colors.white : colors.secondarynew,
      child: InkWell(
        onTap: () => _markAsReadAndNavigate(notification.id, bookingIds),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color:
                            notification.isRead ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              if (notification.body != null && notification.body!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    notification.body!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: notification.isRead ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: notification.isRead ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
