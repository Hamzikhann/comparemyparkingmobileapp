import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/TopBar.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final GeneralRepository _repository = GeneralRepository();
  late Future<SearchResultResponse> _searchFuture;
  bool _showAvailableOnly = false;

  @override
  void initState() {
    super.initState();
    _searchFuture = _performSearch();
  }

  Future<SearchResultResponse> _performSearch() async {
    try {
      return await _repository.searchParking(
        startDate: Globals.startDate,
        endDate: Globals.endDate,
        airport: "STN",
        startTime: Globals.startTime,
        endTime: Globals.endTime,
      );
    } catch (e) {
      throw Exception('Failed to search parking: $e');
    }
  }

  void _toggleAvailableFilter(bool value) {
    setState(() {
      _showAvailableOnly = value;
    });
  }

  void _retrySearch() {
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
            TopBar(
              greeting: 'Packages',
              onBackPressed: () => Navigator.pop(context),
            ),
            
            // Date/time and availability filter in one row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date and time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  
                  ),
                  
                  // Availability badge
                  Container(
                   
                    
                        child: Row(
                          children: [
                            Text(
                              'Available Bookings:',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Switch(
                              value: _showAvailableOnly,
                              onChanged: _toggleAvailableFilter,
                              activeColor: colors.primary,
                            ),
                          ],
                        
                     
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: FutureBuilder<SearchResultResponse>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center();
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
                    final results = snapshot.data!.data.results;
                    final filteredResults = _showAvailableOnly
                        ? results.where((item) => 
                            !item.price.contains('Sorry'))
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

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      itemCount: filteredResults.length,
                      itemBuilder: (context, index) {
                        return _buildPackageCard(filteredResults.elementAt(index));
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
  final isAvailable = !option.price.contains('Sorry');

  // Remove "More info Terms And Conditions" from description
  final cleanedDescription = option.description
      .replaceAll('More info', '')
      .replaceAll('Terms And Conditions', '')
      .trim();

  return Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/ticket.svg',
                height: 50.0,
                width: 50.0,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Text(cleanedDescription),
          SizedBox(height: 16.0),
          // Bullet points for amenities
          Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: Colors.black),
              SizedBox(width: 4.0),
              Text("Meet at Terminal"),
            ],
          ),
          Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: Colors.black),
              SizedBox(width: 4.0),
              Text("24/7 Security"),
            ],
          ),
          Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: Colors.black),
              SizedBox(width: 4.0),
              Text("CCTV"),
            ],
          ),
          Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: Colors.black),
              SizedBox(width: 4.0),
              Text("Security Fencing"),
            ],
          ),
          SizedBox(height: 16.0),
          if (isAvailable) ...[
            Text(
              'Price: ${option.price}',
              style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold,color: Colors.black),
            ),
            SizedBox(height: 8.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleBooking(option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.red,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}


  void _handleBooking(ParkingOption option) {
    Navigator.pushNamed(
    context,
    MyRoutes.reserveBooking,
    arguments: option, // optional, if you want to pass data
  );
  }
}