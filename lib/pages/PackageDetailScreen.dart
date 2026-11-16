import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/booking_flow.dart';
import 'package:parkingapp/data/models/PackageDetailModel.dart';
import 'package:parkingapp/data/models/SearchResultResponse.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/data/site_config_store.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/utils/colors.dart';
import 'package:parkingapp/widgets/CustomButton.dart';
import 'package:parkingapp/widgets/TopBar.dart';

/// One package, as the website's package-details page: the list data straight away,
/// then the full content from GET /api/search/v5/package/:packageId.
class PackageDetailScreen extends StatefulWidget {
  const PackageDetailScreen({super.key});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  PackageDetail? _detail;
  bool _loadingDetail = false;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    SiteConfigStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadDetail() async {
    final id = Globals.option?.packageId ?? '';
    if (id.isEmpty) return;
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    try {
      final detail = await GeneralRepository().getPackageDetails(id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (!mounted) return;
      // e.g. "This package has expired. Please search again."
      setState(() => _detailError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ParkingOption? option = Globals.option;

    if (option == null) {
      return const Scaffold(
        body: Center(child: Text("No package details available")),
      );
    }

    final detail = _detail;
    final features = (detail?.features.isNotEmpty ?? false)
        ? detail!.features
        : option.bulletPoints;
    final marketing = SiteConfigStore.current;
    final price = option.priceValue;
    final comparisons = (!option.isFullyBooked &&
            marketing.priceComparison &&
            price > 0)
        ? comparisonPrices(price)
        : <ComparisonPrice>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TopBar(
                  greeting: "PARKING DETAIL",
                  onBackPressed: () => Navigator.pop(context),
                ),
              ),

              // Image (our tier image, else the provider logo)
              Container(
                width: double.infinity,
                height: 200.h,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: option.imageUrl.isNotEmpty
                    ? Image.network(
                        option.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.local_parking,
                            size: 48.sp, color: Colors.grey),
                      )
                    : Icon(Icons.local_parking,
                        size: 48.sp, color: Colors.grey),
              ),

              SizedBox(height: 16.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    if (features.isNotEmpty) ...[
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children:
                            features.take(3).map((tag) => _tag(tag)).toList(),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    if (option.summary.isNotEmpty) ...[
                      Text(
                        option.summary,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: colors.secondarynew,
                          fontFamily: 'Archivo',
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

                    // Price and comparison
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _priceBox(option, marketing)),
                        if (comparisons.isNotEmpty) ...[
                          SizedBox(width: 16.w),
                          Expanded(child: _comparisonBox(comparisons)),
                        ],
                      ],
                    ),
                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: option.isFullyBooked
                                ? "Fully Booked"
                                : "Reserve This Parking",
                            onPressed: option.isFullyBooked
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                        context, MyRoutes.reserveBooking);
                                  },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // Full content from the package-details API
                    if (_loadingDetail)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (_detailError != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 24.h),
                        child: Text(
                          _detailError!,
                          style:
                              TextStyle(fontSize: 13.sp, color: Colors.red[700]),
                        ),
                      )
                    else
                      ..._detailSections(option, detail, features),

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

  List<Widget> _detailSections(
      ParkingOption option, PackageDetail? detail, List<String> features) {
    final s = detail?.sections;
    final follow = option.followUpPage;
    // API sections first; the search's followUpPage while/if the detail is missing
    final overview = (s?.overview.isNotEmpty ?? false)
        ? s!.overview
        : (follow?.overview ?? '');
    final serviceDetails = (s?.serviceDetails.isNotEmpty ?? false)
        ? s!.serviceDetails
        : (follow?.serviceDetails ?? '');
    final experience = (s?.customerExperience.isNotEmpty ?? false)
        ? s!.customerExperience
        : (follow?.customerExperience ?? '');
    final location = (s?.location.isNotEmpty ?? false)
        ? s!.location
        : (follow?.location ?? '');
    final info = detail?.airportInfo;

    return [
      _section("Overview", overview),
      if (features.isNotEmpty) _featureList(features),
      _section("Service Details", serviceDetails),
      _section("Customer Experience", experience),
      _section("Location", location),
      _section("On Arrival", s?.onArrival ?? ''),
      _section("On Return", s?.onReturn ?? ''),
      if (info != null) _airportInfo(info),
      if (detail != null && detail.reviews.isNotEmpty)
        _reviews(detail.reviews),
    ];
  }

  Widget _tag(String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3E8),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: const Color(0xFF2E7D32),
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _priceBox(ParkingOption option, SiteConfig marketing) {
    final showWas = !option.isFullyBooked &&
        option.originalPrice > option.priceValue &&
        option.priceValue > 0;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3E8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            option.isFullyBooked ? "Availability" : "Our Price",
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Archivo',
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          if (showWas)
            Text(
              formatPrice(option.originalPrice),
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            option.displayPrice,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: option.isFullyBooked ? 20.sp : 28.sp,
              fontFamily: 'Archivo',
              fontWeight: FontWeight.bold,
              color: option.isFullyBooked
                  ? Colors.red[700]
                  : const Color(0xFF1B3D38),
            ),
          ),
          if (!option.isFullyBooked) ...[
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
          ],
          if (!option.isFullyBooked &&
              option.priceDiscount > 0 &&
              marketing.savingsText.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3200),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                marketing.savingsText,
                style: TextStyle(fontSize: 11.sp, color: Colors.white),
              ),
            ),
          ],
          if (option.rating > 0) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20.sp),
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
            if (option.reviews > 0)
              Text(
                "${option.reviews} reviews",
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
          ],
        ],
      ),
    );
  }

  Widget _comparisonBox(List<ComparisonPrice> comparisons) {
    return Container(
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
            "Price Comparison",
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'Archivo',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          for (final c in comparisons)
            _buildCompetitorRow(c.logoAsset, formatPrice(c.price),
                "Save ${formatPrice(c.savings)}"),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Archivo',
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content.trim(),
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6B6B6B),
              fontFamily: 'Archivo',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureList(List<String> features) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's Included",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Archivo',
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 8.h),
          for (final f in features.take(8))
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16.sp, color: Colors.green),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(f,
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[800],
                            fontFamily: 'Archivo')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _airportInfo(AirportInfo info) {
    final rows = <(IconData, String)>[
      if (info.fullAddress.isNotEmpty) (Icons.location_on_outlined, info.fullAddress),
      if (info.contactNumber.isNotEmpty) (Icons.phone_outlined, info.contactNumber),
      if (info.contactEmail.isNotEmpty) (Icons.email_outlined, info.contactEmail),
    ];
    if (rows.isEmpty && info.extraInstructions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Airport Information",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Archivo',
            ),
          ),
          SizedBox(height: 10.h),
          for (final r in rows)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(r.$1, size: 18.sp, color: const Color(0xFF1B3D38)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: SelectableText(r.$2,
                        style: TextStyle(fontSize: 13.sp)),
                  ),
                ],
              ),
            ),
          if (info.extraInstructions.isNotEmpty)
            Text(info.extraInstructions,
                style: TextStyle(
                    fontSize: 13.sp, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }

  Widget _reviews(List<PackageReview> reviews) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reviews (${reviews.length})",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Archivo',
            ),
          ),
          SizedBox(height: 8.h),
          for (final r in reviews.take(20))
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < r.rating.round().clamp(0, 5); i++)
                        Icon(Icons.star, size: 14.sp, color: Colors.amber),
                      if (r.rating > 0) SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          r.author.isNotEmpty ? r.author : "Anonymous",
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (r.date.isNotEmpty)
                        Text("  • ${r.date}",
                            style: TextStyle(
                                fontSize: 11.sp, color: Colors.grey[600])),
                    ],
                  ),
                  if (r.text.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(r.text,
                        style: TextStyle(
                            fontSize: 13.sp, color: Colors.grey[800])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompetitorRow(String imagePath, String price, String saving) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            imagePath,
            width: 40.w,
            height: 20.h,
            fit: BoxFit.contain,
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
              Text(saving,
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

  Widget _buildOtherGreatOptions(
      BuildContext context, ParkingOption currentOption) {
    final currentPrice = currentOption.isFullyBooked
        ? double.infinity
        : currentOption.priceValue;

    // Cheaper bookable packages from the same search, cheapest first
    final List<ParkingOption> displayOptions = Globals.searchResults
        .where((opt) =>
            !opt.isFullyBooked &&
            opt.priceValue > 0 &&
            opt.priceValue < currentPrice &&
            (opt.packageId ?? opt.name) !=
                (currentOption.packageId ?? currentOption.name))
        .toList()
      ..sort((a, b) => a.priceValue.compareTo(b.priceValue));

    if (displayOptions.isEmpty) return const SizedBox.shrink();
    final shown = displayOptions.take(4).toList();

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
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: (shown.length / 2).ceil(),
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final first = index * 2;
            final second = first + 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildOptionCard(context, shown[first])),
                SizedBox(width: 16.w),
                Expanded(
                  child: second < shown.length
                      ? _buildOptionCard(context, shown[second])
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, ParkingOption option) {
    final isMeetGreet = option.name.toLowerCase().contains("meet") ||
        option.type?.toLowerCase().contains("meet") == true;
    final themeColor =
        isMeetGreet ? const Color(0xFF7B1FA2) : const Color(0xFF1565C0);
    final marketing = SiteConfigStore.current;

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: themeColor,
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
                Text(
                  option.displayPrice,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Archivo',
                  ),
                ),
                if (option.priceDiscount > 0 &&
                    marketing.savingsText.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      marketing.savingsText,
                      style: TextStyle(
                          fontSize: 8.sp,
                          color: Colors.green,
                          fontFamily: 'Archivo'),
                    ),
                  ),
                if (option.bulletPoints.isNotEmpty) ...[
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
                ],
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Globals.option = option;
                      Navigator.pushReplacementNamed(
                          context, MyRoutes.packageDetail);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B3D38),
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
