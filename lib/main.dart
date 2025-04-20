import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // Add this import
import 'package:parkingapp/pages/BookingDetailUser.dart';
import 'package:parkingapp/pages/EditProfile.dart';
import 'package:parkingapp/pages/ForgotPassword.dart';
import 'package:parkingapp/pages/LoginScreen.dart';
import 'package:parkingapp/pages/MainScreen.dart';
import 'package:parkingapp/pages/OtpScreen.dart';
import 'package:parkingapp/pages/PackagesScreen.dart';
import 'package:parkingapp/pages/ReserveBookingScreen.dart';
import 'package:parkingapp/pages/SignupScreen.dart';
import 'package:parkingapp/pages/SupportScreen.dart';
import 'package:parkingapp/pages/driver/BookingDetailDriver.dart';
import 'package:parkingapp/pages/driver/DriverHome.dart';
import 'package:provider/provider.dart';
import 'package:parkingapp/pages/PaymentsScreen.dart';
import 'package:parkingapp/pages/SplashScreen.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/providers/ThemeChanger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // // Initialize Stripe
   Stripe.publishableKey = 'pk_test_51RE9h3QsW9cgGLSGZZo6d3ttIhwMgD9fHxU5QGzOe7xgW3RybHokUOQWpq8saaT9Gy23BCcn2m5yJepjYnPmEYzK00QpUXVCtv'; // Replace with your key
  await Stripe.instance.applySettings();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeChanger()),
        ChangeNotifierProvider(create: (_) => AlertNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Alertify.init(context);
    EasyLoading.instance
      ..dismissOnTap = true
      ..loadingStyle = EasyLoadingStyle.light
      ..indicatorWidget = Image.asset('assets/images/load.gif');

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: EasyLoading.init(),
          theme: ThemeData.light(),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/signUp': (context) => SignupScreen(),
            '/forgot': (context) => Forgotpassword(),
            '/otp': (context) => OtpScreen(),
            '/reserveBooking': (context) => ReserveBookingScreen(),
            '/packagesScreen': (context) => PackagesScreen(),
            '/main': (context) => MainScreen(),
            '/payment': (context) => PaymentScreen(),
            '/driverhome': (context) => Driverhome(),
            '/bookingDetail': (context) => Bookingdetaildriver(),
            '/editProfile': (context) => Editprofile(),
            '/support': (context) => SupportScreen(),
            '/bookingDetailUser': (context) => Bookingdetailuser(),
          },
        );
      },
    );
  }
}