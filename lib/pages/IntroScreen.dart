import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/utils/colors.dart';
import '../routes/MyRoutes.dart';
import '../widgets/PrimaryButton.dart'; // import the button

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/intro.svg",
      "title": "Best Parking Spots",
      "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    },
    {
      "image": "assets/images/intro2.svg",
      "title": "Airport Parking",
      "description": "Find and book a parking spot in just a few clicks."
    },
    {
      "image": "assets/images/intro3.svg",
      "title": "Easy Payments",
      "description": "Your vehicle is safe with our secure parking services."
    }
  ];

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              physics: BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        _pages[index]["image"]!,
                        height: 250.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 40.h),
                      Text(
                        _pages[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Text(
                        _pages[index]["description"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /// Show Dots or not
          if (_currentIndex < _pages.length - 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentIndex == index ? 10.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color:
                        _currentIndex == index ? colors.primary : colors.gray,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

          SizedBox(height: 20.h),

          /// Bottom Buttons
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: _currentIndex < _pages.length - 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                                context, MyRoutes.loginRoute);
                          },
                          child: Text(
                            "SKIP",
                            style: TextStyle(
                              fontFamily: 'Archivo',
                              fontSize: 14.sp,
                              color: colors.gray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _nextPage,
                          child: Text(
                            "NEXT",
                            style: TextStyle(
                              fontFamily: 'Archivo',
                              fontSize: 14.sp,
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : PrimaryButton(
                      text: "Get Started",
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, MyRoutes.loginRoute);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
