import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/TopBar.dart';

class PackageDetailScreen extends StatelessWidget {
  const PackageDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the ParkingOption from Globals
    final ParkingOption? option = Globals.option;

    if (option == null) {
      return Scaffold(
        body: Center(child: Text("No package details available")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar / Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TopBar(
                  greeting: "PARKING DETAIL",
                  onBackPressed: () => Navigator.pop(context),
                  // Adjust TopBar if it doesn't support custom title or back button correctly
                  // Assuming TopBar has these params based on usage in PackagesScreen
                ),
              ),

              // 2. Main Image
              Container(
                width: double.infinity,
                height: 200.h,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  image: DecorationImage(
                    image: (option.image != null && option.image!.isNotEmpty)
                        ? NetworkImage(option.image!)
                        : const AssetImage(
                                'assets/images/parking_placeholder.jpg')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Title
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // 4. Tags
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: option.bulletPoints.take(3).map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(
                                0xFFE8F3E8), // Light green background
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: const Color(0xFF2E7D32), // Dark green text
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.h),

                    // 5. Description
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colors.secondarynew,
                        fontFamily: 'Archivo',
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // 6. Price and Compare Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Best Price Box
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3E8),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Best Price",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: 'Archivo',
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  option.price,
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontFamily: 'Archivo',
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1B3D38),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  "All inclusive • No hidden fees",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontFamily: 'Archivo',
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "Save £4.95", // Hardcoded or calculated?
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontFamily: 'Archivo',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 20.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "${option.rating}",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontFamily: 'Archivo',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),

                        // Right: Competitors (Placeholder for now)
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "You Save vs Competitors",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontFamily: 'Archivo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                _buildCompetitorRow("Compare", "£57.82"),
                                _buildCompetitorRow("Pye", "£57.82"),
                                _buildCompetitorRow("Owl", "£57.82"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // 7. Bottom Features Strip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFeatureItem("24/7 CCTV Security"),
                        Container(width: 1, height: 20, color: Colors.grey),
                        _buildFeatureItem("24/7 Service"),
                        Container(width: 1, height: 20, color: Colors.grey),
                        _buildFeatureItem("Airport Location"),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // 8. Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: "Reserve This Parking",
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, MyRoutes.reserveBooking);
                            },
                            // Add color customization if CustomButton supports it
                            // style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1B3D38)),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D8F6F),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),

                    // 9. Other Great Options
                    _buildOtherGreatOptions(context, option),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitorRow(String name, String price) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.circle,
                  size: 16, color: Colors.blue), // Placeholder icon
              SizedBox(width: 4.w),
              Text(name, style: TextStyle(fontSize: 10.sp)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: 'Archivo',
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey)),
              Text("Save £13.06",
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.green,
                    fontFamily: 'Archivo',
                  )),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        fontFamily: 'Archivo',
        color: const Color(0xFF1B3D38),
      ),
    );
  }

  double _parsePrice(String price) {
    if (price.toLowerCase().contains("sorry")) return 999999.0;
    String clean = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  Widget _buildOtherGreatOptions(
      BuildContext context, ParkingOption currentOption) {
    final currentPrice = _parsePrice(currentOption.price);

    // 1. Get all candidates: Exclude self and unavailable items
    List<ParkingOption> candidates = Globals.searchResults.where((opt) {
      if (opt.name == currentOption.name) return false;
      if (opt.price.toLowerCase().contains("sorry")) return false;
      return true;
    }).toList();

    // 2. Filter strictly cheaper than current option
    List<ParkingOption> cheaperOptions = candidates.where((opt) {
      return _parsePrice(opt.price) < currentPrice;
    }).toList();

    // 3. Sort by price (cheapest first)
    cheaperOptions
        .sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));

    // 4. Take top 4 of available cheaper options
    List<ParkingOption> displayOptions = cheaperOptions.take(4).toList();

    return Column(
      children: [
        Center(
          child: Text(
            "Other Great Options",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Archivo',
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            "Compare with these alternative parking services to find\nyour perfect match",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'Archivo',
              color: Colors.grey[600],
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // Static Promo Cards
        Row(
          children: [
            Expanded(
                child: _buildStaticPromoCard(
              icon: Icons.person,
              title: "Meet & Greet",
              subtitle: "Maximum Convenience",
              color: const Color(0xFF9C27B0), // Purple
              bgColor: const Color(0xFFF3E5F5),
            )),
            SizedBox(width: 16.w),
            Expanded(
                child: _buildStaticPromoCard(
              icon: Icons.directions_car,
              title: "Park & Ride",
              subtitle: "Best Value",
              color: const Color(0xFF1976D2), // Blue
              bgColor: const Color(0xFFE3F2FD),
            )),
          ],
        ),
        SizedBox(height: 24.h),

        // Dynamic Options Grid
        if (displayOptions.isNotEmpty)
          ListView.separated(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: (displayOptions.length / 2).ceil(),
            separatorBuilder: (context, index) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              int firstIndex = index * 2;
              int secondIndex = firstIndex + 1;
              return Row(
                children: [
                  Expanded(
                      child: _buildOptionCard(
                          context, displayOptions[firstIndex])),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: secondIndex < displayOptions.length
                        ? _buildOptionCard(context, displayOptions[secondIndex])
                        : Container(),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildStaticPromoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16.sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: 'Archivo',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: color.withOpacity(0.8),
                        fontFamily: 'Archivo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildCheckItem("Drive directly to terminal", color),
          _buildCheckItem("No shuttle buses needed", color),
          _buildCheckItem("Professional chauffeurs", color),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.sp,
                color: color.withOpacity(0.9),
                fontFamily: 'Archivo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, ParkingOption option) {
    bool isMeetGreet = option.name.toLowerCase().contains("meet") ||
        option.type?.toLowerCase().contains("meet") == true;
    Color themeColor = isMeetGreet
        ? const Color(0xFF7B1FA2)
        : const Color(0xFF1565C0); // Purple : Blue
    Color headerColor = themeColor;

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Archivo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (option.rating > 4.0)
                  Icon(Icons.star, color: Colors.amber, size: 14.sp),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      option.price,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Archivo',
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        "Save £5.00",
                        style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.green,
                            fontFamily: 'Archivo'),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 8.h),
                Text("Main Features:",
                    style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Archivo')),
                SizedBox(height: 4.h),
                ...option.bulletPoints.take(3).map((bp) => Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 10.sp, color: Colors.green),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              bp,
                              style: TextStyle(
                                  fontSize: 9.sp,
                                  color: Colors.grey[700],
                                  fontFamily: 'Archivo'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Select this option and reload page or navigate back with it
                      Globals.option = option;
                      Navigator.pushReplacementNamed(
                          context, MyRoutes.packageDetail);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF1B3D38), // Dark Green button
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r)),
                      minimumSize: Size(0, 32.h),
                    ),
                    child: Text(
                      "Choose This Option ->",
                      style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontFamily: 'Archivo'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
