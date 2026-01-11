import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';
import '../routes/MyRoutes.dart';
import '../widgets/PrimaryButton.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/car.png",
      "title": "Real-Time Parking Solutions at your fingertips",
      "description":
          "These rules and regulations for the use of Dummy University Parking Area. In these Rules, unless the context otherwise requires"
    },
    {
      "image": "assets/images/flight.png",
      "title": "Real-Time Parking Solutions at your fingertips",
      "description":
          "These rules and regulations for the use of Dummy University Parking Area. In these Rules, unless the context otherwise requires"
    }
  ];

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, MyRoutes.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Column(
            children: [
              /// IMAGE (50% HEIGHT)
              SizedBox(height: 60.h),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
                child: Image.asset(
                  _pages[index]["image"]!,
                  fit: BoxFit.fitWidth,
                ),
              ),

              SizedBox(height: 10.h),

              /// TITLE
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  _pages[index]["title"]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              SizedBox(height: 15.h),

              /// DESCRIPTION
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  _pages[index]["description"]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ),

              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: _currentIndex == index ? 12.w : 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? colors.primaryNew
                          : colors.gray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              /// BUTTON (CENTERED)
              SizedBox(
                width: 200.w,
                height: 40.h,
                child: PrimaryButton(
                  text: _currentIndex < _pages.length - 1
                      ? "NEXT"
                      : "GET STARTED",
                  onPressed: _nextPage,
                ),
              ),

              /// SKIP TEXT
              if (_currentIndex < _pages.length - 1) ...[
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                        context, MyRoutes.loginRoute);
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 16.sp,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
