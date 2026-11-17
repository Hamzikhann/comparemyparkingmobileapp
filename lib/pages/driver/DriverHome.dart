import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/EditProfile.dart';
import 'package:parkingapp/pages/driver/driver_helpers.dart';
import 'package:parkingapp/utils/colors.dart';

/// Home tab for employees (drivers): greeting, job counts and upcoming jobs.
class Driverhome extends StatefulWidget {
  /// Called with `true` for completed jobs, `false` for active jobs,
  /// so the main screen can switch to the Jobs tab.
  final void Function(bool completed)? onViewAllJobs;

  const Driverhome({Key? key, this.onViewAllJobs}) : super(key: key);

  @override
  State<Driverhome> createState() => _DriverhomeState();
}

class _DriverhomeState extends State<Driverhome> {
  final GeneralRepository _repository = GeneralRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<Parking> _active = [];
  List<Parking> _completed = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _repository.getBookingsForDriver();
      if (!mounted) return;
      setState(() {
        _active = response.assignedAssignments;
        _completed = response.completedAssignmnets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "Failed to load jobs: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = Globals.user;
    final hasImage = user?.imageURL != null && user!.imageURL!.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Editprofile()),
          );
          if (mounted) setState(() {});
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundImage: hasImage
                  ? (user.imageURL!.startsWith('http')
                      ? CachedNetworkImageProvider(user.imageURL!)
                      : FileImage(File(user.imageURL!)) as ImageProvider)
                  : const AssetImage('assets/images/user.png'),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, ${user?.firstName ?? ''}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Archivo',
                      color: colors.primaryNew,
                    ),
                  ),
                  Text(
                    "Employee",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: 'Archivo',
                      color: const Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _active.isEmpty && _completed.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: colors.primaryNew));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryNew),
                child:
                    const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colors.primaryNew,
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard("Active Jobs", _active.length,
                    Icons.schedule, colors.primaryNew,
                    onTap: () => widget.onViewAllJobs?.call(false)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statCard("Completed", _completed.length,
                    Icons.check_circle_outline, colors.secondarynew,
                    onTap: () => widget.onViewAllJobs?.call(true)),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _sectionHeader("Active Jobs", _active.length,
              () => widget.onViewAllJobs?.call(false)),
          SizedBox(height: 12.h),
          if (_active.isEmpty)
            _emptyText("No active jobs right now")
          else
            ..._active
                .take(3)
                .map((p) => buildDriverSessionCard(context, p, 'active')),
          SizedBox(height: 16.h),
          _sectionHeader("Recently Completed", _completed.length,
              () => widget.onViewAllJobs?.call(true)),
          SizedBox(height: 12.h),
          if (_completed.isEmpty)
            _emptyText("No completed jobs yet")
          else
            ..._completed
                .take(2)
                .map((p) => buildDriverSessionCard(context, p, 'completed')),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 12.h),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Archivo',
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontFamily: 'Archivo',
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count, VoidCallback onViewAll) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Archivo',
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        if (count > 0)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              "View all",
              style: TextStyle(
                fontSize: 14.sp,
                fontFamily: 'Archivo',
                fontWeight: FontWeight.w600,
                color: colors.secondarynew,
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontFamily: 'Archivo',
          color: Colors.grey[500],
        ),
      ),
    );
  }
}
