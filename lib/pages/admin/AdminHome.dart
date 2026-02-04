import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/BookingAdminModel.dart';
import 'package:parkingapp/data/models/Driver.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/admin/PaymentsScreen.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parkingapp/data/models/DashboardDataModel.dart';
import 'package:parkingapp/data/models/AdminDashboardModel.dart';
import 'package:parkingapp/pages/admin/TopBar.dart';
import 'package:url_launcher/url_launcher.dart';

class Adminhome extends StatefulWidget {
  const Adminhome({Key? key}) : super(key: key);

  @override
  State<Adminhome> createState() => _ReserveBookingScreenState();
}

class _ReserveBookingScreenState extends State<Adminhome> {
  late Future<BookingAdminResponse> _bookingsFuture;
  final GeneralRepository _repository = GeneralRepository();
  bool _isLoading = true;
  String? _errorMessage;

  String _filter = 'weekly';
  DashboardDataResponse? _dashboardData;
  AdminDashboardResponse? _mainDashboardData;

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
      _bookingsFuture = _repository.getBookingsForAdmin();
      await _bookingsFuture;

      // Fetch dashboard data
      _dashboardData = await _repository.getDashboardData(_filter);
      _mainDashboardData = await _repository.getMainDashboardData();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load data: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDashboard() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _dashboardData = await _repository.getDashboardData(_filter);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update dashboard: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchDrivers() async {
    try {
      final response = await GeneralRepository().getEmployeesWithBookings();
      final employeesData = response['data'] as List;
      Globals.drivers =
          employeesData.map((json) => Driver.fromJson(json)).toList();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load drivers: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit; // If true, allow back navigation; if false, puet it
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                title: '',
                leftSideText: "Compare My Parking",
                showBackButton: false,
                showPayments: true,
                onPaymentPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PaymentScreenAdmin()));
                },
                onBackPressed: () {},
                onLogoutPressed: () {
                  // Handle logout
                  Globals.user = null;
                  SharedStorage.removeFromSharedPreferences();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      MyRoutes.loginRoute, (route) => false);
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF4B725D),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.7,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_errorMessage!),
                                      SizedBox(height: 16.h),
                                      ElevatedButton(
                                        onPressed: _loadData,
                                        child: const Text("Retry"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : FutureBuilder<BookingAdminResponse>(
                              future: _bookingsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center();
                                } else if (snapshot.hasError) {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.7,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text("Error: ${snapshot.error}"),
                                            SizedBox(height: 16.h),
                                            ElevatedButton(
                                              onPressed: _loadData,
                                              child: const Text("Retry"),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasData) {
                                  final pending =
                                      snapshot.data!.pendingParkings;
                                  final reserved =
                                      snapshot.data!.reservedParkings;
                                  final completed =
                                      snapshot.data!.completedParkings;

                                  // Move bookings with empty assignments from reserved to pending
                                  for (var booking in List.from(reserved)) {
                                    if (booking.bookingAssignments.isEmpty) {
                                      pending.add(booking);
                                      reserved.remove(
                                          booking); // Remove from reserved
                                    }
                                  }

                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20.w, vertical: 16.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Top Cards Row 1
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildStatCard(
                                                "Users",
                                                _mainDashboardData
                                                        ?.data.stats.totalUsers
                                                        .toString() ??
                                                    "0",
                                                Icons.people_outline,
                                                Colors.green,
                                              ),
                                            ),
                                            SizedBox(width: 16.w),
                                            Expanded(
                                              child: _buildStatCard(
                                                "Total Bookings",
                                                _mainDashboardData?.data.stats
                                                        .totalBookings
                                                        .toString() ??
                                                    "0",
                                                Icons.arrow_circle_down,
                                                Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16.h),
                                        // Top Cards Row 2
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildStatCard(
                                                "Total Payments",
                                                "£${_mainDashboardData?.data.stats.totalPayments.toString() ?? "0"}",
                                                Icons.notifications_none,
                                                Colors.orange,
                                              ),
                                            ),
                                            const Expanded(child: SizedBox()),
                                          ],
                                        ),
                                        SizedBox(height: 24.h),

                                        // Revenue & Users Chart Card
                                        _buildChartCard(),

                                        SizedBox(height: 32.h),

                                        // Circular Progress Section
                                        _buildCircularProgressCard(),

                                        SizedBox(height: 48.h),
                                      ],
                                    ),
                                  );
                                } else {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.7,
                                      child: const Center(
                                        child: Text("No data available."),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    // Ensure the return type is Future<bool>
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Exit"),
          content: Text("Are you sure you want to exit?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't exit
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Exit
              },
              child: Text("Exit"),
            ),
          ],
        );
      },
    );

    // Return the result or false if the result is null (dialog dismissed)
    return result ?? false;
  }

  Future<void> getLocation(String bookingID) async {
    try {
      final value = await GeneralRepository().getLocationCoordinates(bookingID);
      final longitude = value['longitude'];
      final latitude = value['latitude'];

      if (longitude == null ||
          longitude.isEmpty ||
          latitude == null ||
          latitude.isEmpty) {
        return;
      }

      final googleMapsUrl = Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");
      final appleMapsUrl =
          Uri.parse("http://maps.apple.com/?q=$latitude,$longitude");

      if (Platform.isAndroid) {
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl);
        } else {
          print("Could not open Google Maps on Android.");
        }
      } else if (Platform.isIOS) {
        // Try Google Maps first on iOS
        final iosGoogleMapsUrl =
            Uri.parse("comgooglemaps://?q=$latitude,$longitude");

        if (await canLaunchUrl(iosGoogleMapsUrl)) {
          await launchUrl(iosGoogleMapsUrl);
        } else {
          // Fallback to Apple Maps
          if (await canLaunchUrl(appleMapsUrl)) {
            await launchUrl(appleMapsUrl);
          } else {
            print("Could not open any maps on iOS.");
          }
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Updated just now",
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Revenue & Users",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildFilterToggle(),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildLegendItem("Revenue", Colors.green.shade300),
              SizedBox(width: 12.w),
              _buildLegendItem("Users", Colors.teal),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 200.h,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filter,
          isDense: true,
          style: TextStyle(fontSize: 10.sp, color: Colors.black),
          items: ['weekly', 'monthly'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.toUpperCase()),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _filter = newValue;
              });
              _updateDashboard();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_dashboardData == null || _dashboardData!.data.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.black,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval:
                  1, // Fix: Ensure titles are shown only for integer indices
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                // Check if value is essentially an integer
                if (value % 1 != 0) return const SizedBox();

                if (index >= 0 && index < _dashboardData!.data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _dashboardData!.data[index].name,
                      style: TextStyle(fontSize: 8.sp, color: Colors.black),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _dashboardData!.data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.currentRevenue);
            }).toList(),
            isCurved: true,
            color: Colors.green.shade300,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: _dashboardData!.data.asMap().entries.map((e) {
              return FlSpot(
                  e.key.toDouble(), e.value.currentUsers.toDouble() * 10);
            }).toList(),
            isCurved: true,
            color: Colors.teal,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.green.shade400,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgressCard() {
    if (_mainDashboardData == null) {
      return const SizedBox.shrink();
    }

    final dist = _mainDashboardData!.data.userDistribution;
    final total = dist.active + dist.inactive + dist.newUsers;
    final activePercentage =
        total > 0 ? (dist.active / total * 100).toInt() : 0;

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200.w,
                height: 200.w,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 10,
                    centerSpaceRadius: 70.r,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: dist.active.toDouble(),
                        color: const Color(0xFFF770A1), // Pinkish
                        radius: 20.w,
                        showTitle: false,
                        badgePositionPercentageOffset: 0,
                      ),
                      PieChartSectionData(
                        value: dist.newUsers.toDouble(),
                        color: const Color(0xFF6CF3C6), // Mint
                        radius: 20.w,
                        showTitle: false,
                        badgePositionPercentageOffset: 0,
                      ),
                      PieChartSectionData(
                        value: dist.inactive.toDouble() > 0
                            ? dist.inactive.toDouble()
                            : 0.0,
                        color: const Color(0xFFB0A6F2), // Purple/Blue
                        radius: 20.w,
                        showTitle: false,
                        badgePositionPercentageOffset: 0,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$activePercentage%",
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  Text(
                    "Active Users",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        _buildUserDistributionLegend(dist),
      ],
    );
  }

  Widget _buildUserDistributionLegend(UserDistribution dist) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem("Active: ${dist.active}", const Color(0xFFF770A1)),
        _buildLegendItem("New: ${dist.newUsers}", const Color(0xFF6CF3C6)),
        _buildLegendItem("Inactive: ${dist.inactive}", const Color(0xFFB0A6F2)),
      ],
    );
  }
}
