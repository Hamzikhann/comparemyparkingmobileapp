import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/models/NotificationModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/driver/driver_helpers.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/TopBar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class NotificationsScreenDriver extends StatefulWidget {
  /// false when shown as a bottom-navigation tab.
  final bool showBackButton;

  const NotificationsScreenDriver({super.key, this.showBackButton = true});

  @override
  State<NotificationsScreenDriver> createState() =>
      _NotificationsScreenDriverState();
}

class _NotificationsScreenDriverState extends State<NotificationsScreenDriver> {
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Marks the notification read, then opens the job it is about.
  Future<void> _markAsReadAndNavigate(NotificationModel notification) async {
    try {
      if (!notification.isRead) {
        await _repository.markNotificationsAsRead([notification.id]);
        setState(() {
          final index =
              _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] =
                _notifications[index].copyWith(isRead: true);
          }
        });
      }

      // Older notifications (before job links) have no booking id
      if (notification.bookingId.isEmpty) {
        _snack('This notification is not linked to a job');
        return;
      }

      // Fresh job list (active + completed) for this employee
      final res = await _repository.getBookingsForDriver();
      final all = [...res.assignedAssignments, ...res.completedAssignmnets];
      final match =
          all.where((p) => p.id == notification.bookingId).toList();

      if (!mounted) return;
      if (match.isNotEmpty) {
        openDriverBooking(context, match.first);
      } else {
        // e.g. the job was reassigned to someone else or cancelled
        _snack('This job is no longer assigned to you');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
              showBackButton: widget.showBackButton,
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
                          color: colors.primaryNew,
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
        DateTime.tryParse(notification.createdAt)?.toLocal() ?? DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: notification.isRead
          ? Colors.white
          : colors.primaryNew.withOpacity(0.06),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: () => _markAsReadAndNavigate(notification),
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
                            notification.isRead ? Colors.black : colors.primaryNew,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: colors.primaryNew,
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
                      color: const Color(0xFF6B6B6B),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
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
