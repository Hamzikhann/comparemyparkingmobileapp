import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'dart:math';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final GeneralRepository _repository = GeneralRepository();
  late Future<SearchResultResponse> _searchFuture;
  bool _showAvailableOnly = false;

  DateTime? parsedStartDate;
  DateTime? parsedEndDate;
  TimeOfDay? parsedStartTime;
  TimeOfDay? parsedEndTime;

  @override
  void initState() {
    super.initState();
    _initializeDatesFromGlobals();
    _searchFuture = _performSearch();
    Globals.option = null;
  }

  void _initializeDatesFromGlobals() {
    try {
      if (Globals.startDate.isNotEmpty) {
        parsedStartDate = DateTime.parse(Globals.startDate);
      }
      if (Globals.endDate.isNotEmpty) {
        parsedEndDate = DateTime.parse(Globals.endDate);
      }
      if (Globals.startTime.isNotEmpty) {
        // "h:mm a" format e.g. "2:30 PM"
        // Cleaning string just in case there are extra spaces
        final cleanedStart = Globals.startTime.trim();
        final dt = DateFormat("h:mm a").parse(cleanedStart);
        parsedStartTime = TimeOfDay.fromDateTime(dt);
      }
      if (Globals.endTime.isNotEmpty) {
        final cleanedEnd = Globals.endTime.trim();
        final dt = DateFormat("h:mm a").parse(cleanedEnd);
        parsedEndTime = TimeOfDay.fromDateTime(dt);
      }
    } catch (e) {
      debugPrint("Error parsing globals for dates: $e");
    }
  }

  Future<void> _pickDateAndTime({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime initialDate = today;
    DateTime firstDate = today;

    if (isStart) {
      if (parsedStartDate != null) {
        initialDate = parsedStartDate!;
      }
    } else {
      if (parsedStartDate != null) {
        // Calculate the minimum valid end datetime (Start + 2 hours)
        DateTime minEndDateTime = parsedStartDate!;
        if (parsedStartTime != null) {
          final startDateTime = DateTime(
            parsedStartDate!.year,
            parsedStartDate!.month,
            parsedStartDate!.day,
            parsedStartTime!.hour,
            parsedStartTime!.minute,
          );
          final validEndDateTime = startDateTime.add(const Duration(hours: 2));
          // The first allowable date is the date part of (Start + 2h)
          // This handles the case where Start + 2h pushes into the next day.
          minEndDateTime = DateTime(validEndDateTime.year,
              validEndDateTime.month, validEndDateTime.day);
        }

        firstDate = minEndDateTime;
      }

      if (parsedEndDate != null) {
        initialDate = parsedEndDate!;
      } else {
        initialDate = firstDate;
      }
    }

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4B725D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    // Calculate initial time for picker to suggest a valid time
    TimeOfDay initialTime = TimeOfDay.now();
    if (!isStart && parsedStartDate != null && parsedStartTime != null) {
      final startDateTime = DateTime(
        parsedStartDate!.year,
        parsedStartDate!.month,
        parsedStartDate!.day,
        parsedStartTime!.hour,
        parsedStartTime!.minute,
      );
      // If selected date is same as start date (or the forced next day), suggest appropriate time
      // However, we just want to ensure we don't start before the valid window if that's the date chosen
      final validEndDateTime = startDateTime.add(const Duration(hours: 2));

      // If the user picked the date that corresponds to the minimum valid date
      if (date.year == validEndDateTime.year &&
          date.month == validEndDateTime.month &&
          date.day == validEndDateTime.day) {
        initialTime = TimeOfDay(
            hour: validEndDateTime.hour, minute: validEndDateTime.minute);
      }
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4B725D),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      if (isStart) {
        parsedStartDate = date;
        parsedStartTime = time;
        // Reset end date if it becomes invalid
        if (parsedEndDate != null) {
          final startDateTime =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
          final endDateTime = DateTime(
              parsedEndDate!.year,
              parsedEndDate!.month,
              parsedEndDate!.day,
              parsedEndTime?.hour ?? 0,
              parsedEndTime?.minute ?? 0);

          // Check if existing end date is valid (must be >= start + 2 hours)
          if (endDateTime
              .isBefore(startDateTime.add(const Duration(hours: 2)))) {
            parsedEndDate = null;
            parsedEndTime = null;
          }
        }
      } else {
        parsedEndDate = date;
        parsedEndTime = time;
      }
    });
  }

  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<SearchResultResponse> _performSearch() async {
    try {
      return await _repository
          .searchParking(
        startDate: Globals.startDate,
        endDate: Globals.endDate,
        airport: Globals.selectedAirport,
        startTime: Globals.startTime,
        endTime: Globals.endTime,
        promoCode: Globals.promoCode,
      )
          .then((response) {
        Globals.searchResults = response.data;
        return response;
      });
    } catch (e) {
      throw Exception('Failed to search parking: $e');
    }
  }

  void _retrySearch() {
    if (parsedStartDate == null ||
        parsedStartTime == null ||
        parsedEndDate == null ||
        parsedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please select both Check In and Check Out dates and times')),
      );
      return;
    }

    final startDateTime = DateTime(
      parsedStartDate!.year,
      parsedStartDate!.month,
      parsedStartDate!.day,
      parsedStartTime!.hour,
      parsedStartTime!.minute,
    );
    final endDateTime = DateTime(
      parsedEndDate!.year,
      parsedEndDate!.month,
      parsedEndDate!.day,
      parsedEndTime!.hour,
      parsedEndTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('End date must be greater than or equal to start date')),
      );
      return;
    }

    if (endDateTime.difference(startDateTime).inHours < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Time difference must be at least 2 hours')),
      );
      return;
    }

    // Update Globals before searching
    if (parsedStartDate != null)
      Globals.startDate = _formatDateForApi(parsedStartDate!);
    if (parsedEndDate != null)
      Globals.endDate = _formatDateForApi(parsedEndDate!);
    if (parsedStartTime != null)
      Globals.startTime = _formatTimeForApi(parsedStartTime!);
    if (parsedEndTime != null)
      Globals.endTime = _formatTimeForApi(parsedEndTime!);

    setState(() {
      _searchFuture = _performSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            // Custom Search Bar Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: GestureDetector(
                                onTap: () {
                                  // TODO: Open airport selection or go back to search
                                  Navigator.pop(context);
                                },
                                child: Center(
                                  child: Text(
                                    Globals.selectedAirport.isNotEmpty
                                        ? Globals.selectedAirport
                                        : "Select Airport",
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey[300],
                              thickness: 1,
                              indent: 8,
                              endIndent: 8,
                            ),
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () => _pickDateAndTime(isStart: true),
                                child: Container(
                                  // Transparent container to expand hit test
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          parsedStartDate != null
                                              ? DateFormat('dd MMM')
                                                  .format(parsedStartDate!)
                                              : 'Check In',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontFamily: 'Archivo',
                                            color: parsedStartDate != null
                                                ? Color(0xFF1A1A2E)
                                                : Color(0xFF6B6B6B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (parsedStartTime != null)
                                          Text(
                                            parsedStartTime!.format(context),
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontFamily: 'Archivo',
                                              color: Color(0xFF4B725D),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            VerticalDivider(
                              color: Colors.grey[300],
                              thickness: 1,
                              indent: 8,
                              endIndent: 8,
                            ),
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: () => _pickDateAndTime(isStart: false),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          parsedEndDate != null
                                              ? DateFormat('dd MMM')
                                                  .format(parsedEndDate!)
                                              : 'Check Out',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontFamily: 'Archivo',
                                            color: parsedEndDate != null
                                                ? Color(0xFF1A1A2E)
                                                : Color(0xFF6B6B6B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (parsedEndTime != null)
                                          Text(
                                            parsedEndTime!.format(context),
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontFamily: 'Archivo',
                                              color: Color(0xFF4B725D),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: Color(
                                    0xFF4A6F56), // Greenish color from design
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.search,
                                    color: Colors.white, size: 20.sp),
                                onPressed:
                                    _retrySearch, // Or open search filter
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Promo Code Field
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: TextFormField(
                initialValue: Globals.promoCode,
                onChanged: (value) {
                  Globals.promoCode = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter Promo Code (Optional)',
                  hintStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.local_offer_outlined,
                    color: Color(0xFF4A6F56),
                    size: 20.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Search Result",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder<SearchResultResponse>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Failed to load packages',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          CustomButton(
                            text: 'Retry',
                            onPressed: _retrySearch,
                            isSmall: true,
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasData) {
                    final results = snapshot.data!.data;
                    final filteredResults = _showAvailableOnly
                        ? results
                            .where((item) => !item.price.contains('Sorry'))
                            .toList()
                        : results;

                    if (filteredResults.isEmpty) {
                      return Center(
                        child: Text(
                          _showAvailableOnly
                              ? 'No Bookings available '
                              : 'No packages found',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      itemCount: filteredResults.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        return _buildPackageCard(filteredResults[index]);
                      },
                    );
                  }

                  return Center(child: Text('No data available'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(ParkingOption option) {
    // Determine if we should show tags. If API doesn't return nice tags, use placeholders or skip.
    // The design shows "Quick & Easy" and "Friendly Local Team".
    List<String> tags = option.bulletPoints.take(2).toList();
    if (tags.isEmpty) {
      tags = ["Quick & Easy", "Friendly Local Team"];
    }

    return GestureDetector(
      onTap: () {
        Globals.option = option;
        Navigator.pushNamed(context, MyRoutes.packageDetail);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Image Section
            Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: (option.imagenew != null &&
                              option.imagenew!.isNotEmpty)
                          ? Image.network(
                              option.imagenew!,
                              width: 100.w,
                              height: 100.w,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 100.w,
                                height: 100.w,
                                color: Colors.grey[200],
                                child: Icon(Icons.local_parking,
                                    color: Colors.grey),
                              ),
                            )
                          : Image.network(
                              option.image!,
                              width: 100.w,
                              height: 100.w,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 100.w,
                                height: 100.w,
                                color: Colors.grey[200],
                                child: Icon(Icons.local_parking,
                                    color: Colors.grey),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Color(0xFF6B8E78), // Greenish background
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8.r),
                            bottomRight: Radius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          "Secure My Parking Spot",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 100.w,
                  child: Builder(builder: (context) {
                    final int views =
                        Random(option.name.hashCode).nextInt(70) + 20;
                    final int bought =
                        Random(option.name.hashCode + 1).nextInt(views - 5) + 5;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.remove_red_eye_outlined,
                                size: 14.sp, color: colors.secondarynew),
                            SizedBox(width: 4.w),
                            Text(
                              "$views views",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: colors.secondarynew,
                                fontFamily: 'Archivo',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 14.sp, color: colors.secondarynew),
                            SizedBox(width: 4.w),
                            Text(
                              "$bought bought",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: colors.secondarynew,
                                fontFamily: 'Archivo',
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
            SizedBox(width: 12.w),

            // Right Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Start your journey the easy way with ${option.name}...",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),

                  // Tags
                  Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: tags
                        .map((tag) => Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Color(0xFFE8F3E8), // Light green bg
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Color(0xFF4A6F56),
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 8.h),

                  // Price and Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Best Price",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            option.price.contains('Sorry') ||
                                    option.price.trim().startsWith('£')
                                ? option.price
                                : "£${option.price}",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "All inclusive • No hidden fees",
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20.sp),
                          SizedBox(width: 4.w),
                          Text(
                            option.rating > 0
                                ? "${option.rating}"
                                : "4.6", // Fallback to 4.6 if 0
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
