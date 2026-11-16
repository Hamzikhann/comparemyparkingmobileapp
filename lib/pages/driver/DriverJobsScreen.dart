import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/models/BookingListDriverModel.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/pages/driver/driver_helpers.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/TopBar.dart';

/// Jobs tab for employees (drivers): all active and completed jobs.
class DriverJobsScreen extends StatefulWidget {
  /// Open on the Completed list instead of Active.
  final bool showCompleted;

  const DriverJobsScreen({super.key, this.showCompleted = false});

  @override
  State<DriverJobsScreen> createState() => _DriverJobsScreenState();
}

class _DriverJobsScreenState extends State<DriverJobsScreen> {
  final GeneralRepository _repository = GeneralRepository();
  late bool _showCompleted = widget.showCompleted;
  bool _isLoading = true;
  String? _errorMessage;
  List<Parking> _active = [];
  List<Parking> _completed = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DriverJobsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showCompleted != widget.showCompleted) {
      setState(() => _showCompleted = widget.showCompleted);
    }
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
          children: [
            TopBar(
              greeting: "My Jobs",
              showBackButton: false,
              onBackPressed: () {},
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colors.grayNavLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    _tab("Active (${_active.length})", !_showCompleted,
                        () => setState(() => _showCompleted = false)),
                    _tab("Completed (${_completed.length})", _showCompleted,
                        () => setState(() => _showCompleted = true)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? colors.primaryNew : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Archivo',
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : colors.textGray,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
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

    final items = _showCompleted ? _completed : _active;
    final type = _showCompleted ? 'completed' : 'active';

    return RefreshIndicator(
      color: colors.primaryNew,
      onRefresh: _loadData,
      child: items.isEmpty
          ? ListView(
              children: [
                SizedBox(height: 120.h),
                Icon(Icons.event_busy, size: 64.sp, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    _showCompleted ? "No completed jobs" : "No active jobs",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Archivo',
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  buildDriverSessionCard(context, items[i], type),
            ),
    );
  }
}
