import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for orientation lock
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parkingapp/pages/ForgotPassword.dart';
import 'package:parkingapp/pages/HomeScreen.dart';
import 'package:parkingapp/pages/OtpScreen.dart';
import 'package:parkingapp/pages/SignupScreen.dart';
import 'package:parkingapp/pages/SplashScreen.dart';
import 'package:parkingapp/pages/LoginScreen.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/providers/ThemeChanger.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for orientation lock

  // Lock orientation before running app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeChanger>(
          create: (context) => ThemeChanger(),
        ),
        ChangeNotifierProvider<AlertNotifier>(
          create: (context) => AlertNotifier(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Alertify.init(context);
    EasyLoading.instance.dismissOnTap = true;
    EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
    EasyLoading.instance.indicatorWidget =
        Image.asset('assets/images/load.gif');
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true, // Required for DevicePreview
          locale: DevicePreview.locale(context), // Required for DevicePreview
          //builder: DevicePreview.appBuilder,
          builder: EasyLoading.init(), // Required for DevicePreview
          theme: ThemeData.light(),
          home: SplashScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/signUp': (context) => Signupscreen(),
            '/forgot': (context) => Forgotpassword(),
            '/otp': (context) => OtpScreen(),
            '/home': (context) => HomeScreen(),
          },
        );
      },
    );
  }
}
