import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for orientation lock
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/pages/ForgotPassword.dart';
import 'package:parkingapp/pages/OtpScreen.dart';
import 'package:parkingapp/pages/SignupScreen.dart';
import 'package:parkingapp/pages/SplashScreen.dart';
import 'package:parkingapp/pages/LoginScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for orientation lock

  // Lock orientation before running app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
  //   DevicePreview(
  //     enabled: true, // You can conditionally enable/disable DevicePreview
  //     builder: (context) => MyApp(),
  //   ),
  // );
  const MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true, // Required for DevicePreview
          locale: DevicePreview.locale(context), // Required for DevicePreview
          builder: DevicePreview.appBuilder, // Required for DevicePreview
          theme: ThemeData.light(),
          home: SplashScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/signUp': (context) => Signupscreen(),
            '/forgot': (context) => Forgotpassword(),
            '/otp': (context) => OtpScreen(),
          },
        );
      },
    );
  }
}