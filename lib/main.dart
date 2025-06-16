import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/BookingDetailUser.dart';
import 'package:parkingapp/pages/EditProfile.dart';
import 'package:parkingapp/pages/ForgotPassword.dart';
import 'package:parkingapp/pages/IntroScreen.dart';
import 'package:parkingapp/pages/LoginScreen.dart';
import 'package:parkingapp/pages/MainScreen.dart';
import 'package:parkingapp/pages/NotificationsScreen.dart';
import 'package:parkingapp/pages/OtpScreen.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/pages/PackagesScreen.dart';
import 'package:parkingapp/pages/PrivacyPolicyScreen.dart';
import 'package:parkingapp/pages/ReserveBookingScreen.dart';
import 'package:parkingapp/pages/SignupScreen.dart';
import 'package:parkingapp/pages/SupportScreen.dart';
import 'package:parkingapp/pages/TermsAndConditionsScreen.dart';
import 'package:parkingapp/pages/admin/AddEditDriverScreen.dart';
import 'package:parkingapp/pages/admin/AdminHome.dart';
import 'package:parkingapp/pages/admin/DriverListScreen.dart';
import 'package:parkingapp/pages/admin/PaymentsScreen.dart';
import 'package:parkingapp/pages/driver/BookingDetailDriver.dart';
import 'package:parkingapp/pages/driver/DriverHome.dart';
import 'package:parkingapp/pages/driver/NotificationsScreenDriver.dart';
import 'package:parkingapp/pages/resetOtp/OtpScreen2.dart';
import 'package:provider/provider.dart';
import 'package:parkingapp/pages/PaymentsScreen.dart';
import 'package:parkingapp/pages/SplashScreen.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/providers/ThemeChanger.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Stripe setup
  Stripe.publishableKey =
      'pk_test_51RE9gjJdHKgLpFqJtJp36OmTujMu4dPYEQzmcQyIEPgjJTEyaHuIt1yY6GUGtQJkWa2RVCEgdgltfn7YjwE2athD00oiFutv0Z';
  await Stripe.instance.applySettings();
  Stripe.merchantIdentifier = 'merchant.com.stn00.parkingapp22';
  Stripe.urlScheme = 'flutterstripe';

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Notification setup
  await setupNotifications();

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
          navigatorKey: navigatorKey, // ✅ Required for global navigation
          builder: EasyLoading.init(),
          theme: ThemeData.light(),
          home: const SplashScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/signUp': (context) => SignupScreen(),
            '/forgot': (context) => Forgotpassword(),
            '/otp': (context) => OtpScreen(),
            '/otpSignup': (context) => OtpScreen2(),
            '/reserveBooking': (context) => ReserveBookingScreen(),
            '/packagesScreen': (context) => PackagesScreen(),
            '/main': (context) => MainScreen(),
            '/payment': (context) => PaymentScreen(),
            '/driverhome': (context) => Driverhome(),
            '/bookingDetail': (context) => Bookingdetaildriver(),
            '/editProfile': (context) => Editprofile(),
            '/support': (context) => SupportScreen(),
            '/bookingDetailUser': (context) => Bookingdetailuser(),
            '/privacyPolicy': (context) => PrivacyPolicyScreen(),
            '/termsAndConditions': (context) => TermsAndConditionsScreen(),
            '/adminHome': (context) => Adminhome(),
            '/driverList': (context) => DriverListScreen(),
            '/driverEditAdd': (context) => AddEditDriverScreen(),
            '/paymentsScreen': (context) => PaymentScreenAdmin(),
            '/notifications': (context) => NotificationsScreen(),
            '/notificationsDriver': (context) => NotificationsScreenDriver(),
          },
        );
      },
    );
  }
}

Future<void> setupNotifications() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create Android notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize plugin for displaying notifications
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  // Request notification permissions
  if (Platform.isIOS) {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ iOS: Notification permission granted");

      // Wait for APNs token (required on iOS before getting FCM token)
      String? apnsToken;
      int attempts = 0;

      while (apnsToken == null && attempts < 10) {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        attempts++;
      }

      print("📲 APNs Token: $apnsToken");
    } else {
      print("❌ iOS: Notification permission denied");
      return;
    }
  } else if (Platform.isAndroid) {
    // For Android 13+ permissions
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ✅ Safe to get FCM token now
  //String? fcmToken = await messaging.getToken();
 // print('🎯 FCM Token: $fcmToken');

  // Handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground message: ${message.notification?.title}");

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  });

  // Handle tapped notifications
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📬 Notification opened");
    navigateBasedOnRole();
  });
}


void navigateBasedOnRole() async {
  await SharedStorage.loadUser();

  Future.delayed(const Duration(seconds: 1), () {
    final nav = navigatorKey.currentState!;
    if (Globals.user != null) {
      if (Globals.roleTitle == "Employee") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => Driverhome()));
      } else if (Globals.roleTitle == "Administrator") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => Adminhome()));
      } else {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
      }
    } else {
      if (Globals.roleTitle == "Employee") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => Driverhome()));
      } else if (Globals.roleTitle == "Administrator") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => Adminhome()));
      } else {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => IntroScreen()));
      }
    }
  });
}
