import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:parkingapp/web/web_frame.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:parkingapp/data/shared/SharedStorage.dart';
import 'package:parkingapp/pages/BookingDetailUser.dart';
import 'package:parkingapp/pages/BookingClaimDetailScreen.dart';
import 'package:parkingapp/pages/EditProfile.dart';
import 'package:parkingapp/pages/ForgotPassword.dart';
import 'package:parkingapp/pages/HomeScreen.dart';
import 'package:parkingapp/pages/IntroScreen.dart';
import 'package:parkingapp/pages/LoginScreen.dart';
import 'package:parkingapp/pages/MainScreen.dart';
import 'package:parkingapp/pages/NotificationsScreen.dart';
import 'package:parkingapp/services/push_token.dart';
import 'package:parkingapp/pages/OtpScreen.dart';
import 'dart:convert';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chat_screen.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/data/repositories/general_repository.dart';
import 'package:parkingapp/routes/MyRoutes.dart';
import 'package:parkingapp/services/job_push.dart';
import 'package:parkingapp/pages/PackageDetailScreen.dart';
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
import 'package:parkingapp/pages/driver/DriverMainScreen.dart';
import 'package:parkingapp/pages/driver/NotificationsScreenDriver.dart';
import 'package:parkingapp/pages/resetOtp/OtpScreen2.dart';
import 'package:parkingapp/pages/LoginSelectionScreen.dart';
import 'package:provider/provider.dart';
import 'package:parkingapp/pages/PaymentsScreen.dart';
import 'package:parkingapp/pages/SplashScreen.dart';
import 'package:parkingapp/pages/BookingConfirmationScreen.dart';
import 'package:parkingapp/providers/AlertNotifier.dart';
import 'package:parkingapp/providers/Alertify.dart';
import 'package:parkingapp/providers/ThemeChanger.dart';
import 'package:parkingapp/services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

// Runs in a separate isolate when a push arrives while the app is closed;
// the annotation keeps it callable from native code in release/AOT builds.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web is the staff desktop version: no Firebase, Stripe or phone
  // notifications there (alerts come over the chat socket instead).
  if (!kIsWeb) {
  await Firebase.initializeApp();

  // Stripe setup
  Stripe.publishableKey =
      'pk_live_51RW4T2GrYrmFa4AwNLWGiNdEP3wHHW5F095Jj6ygcdGQvkYtdDEZsCuUkt3fQXmF1PGWFTUAcOk1CtXO2eatrVvv00YLI6tuLG';
  Stripe.merchantIdentifier = 'merchant.com.comparemyparking'; // ✅ Apple Pay merchant ID
  await Stripe.instance.applySettings();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Notification setup
  await setupNotifications();
  // Send a new push token to the server whenever Firebase changes it
  PushToken.sync();

  // Initialize download notification service
  await NotificationService().initialize();
  }

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
      ..indicatorType = EasyLoadingIndicatorType.ring;

    // Web (staff desktop version): phone-width column, see WebFrame
    if (kIsWeb) return WebFrame(builder: (_) => _app());
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => _app(),
    );
  }

  Widget _app() {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey, // ✅ Required for global navigation
          builder: EasyLoading.init(),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4B725D),
              primary: const Color(0xFF4B725D),
              secondary: const Color(0xFF214D53),
            ),
            fontFamily: 'Archivo',
          ),
          home: const SplashScreen(),
          routes: appRoutes,
        );
  }
}

/// Named routes (also used by the web desktop layout's content pane).
final Map<String, WidgetBuilder> appRoutes = {
            '/login': (context) => LoginScreen(),
            '/signUp': (context) => SignupScreen(),
            '/forgot': (context) => Forgotpassword(),
            '/otp': (context) => OtpScreen(),
            '/otpSignup': (context) => OtpScreen2(),
            '/reserveBooking': (context) => ReserveBookingScreen(),
            '/packagesScreen': (context) => PackagesScreen(),
            '/main': (context) => MainScreen(),
            '/payment': (context) => PaymentScreen(),
            '/driverhome': (context) => const DriverMainScreen(),
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
            '/packageDetail': (context) => PackageDetailScreen(),
            '/bookingConfirmation': (context) => BookingConfirmationScreen(),
            '/home': (context) => HomeScreen(),
            // Web is staff-only: straight to login, no guest/sign-up choice
            '/selection': (context) =>
                kIsWeb ? LoginScreen() : const LoginSelectionScreen(),
            '/claimDetail': (context) => BookingClaimDetailScreen(
                  bookingData: ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>,
                ),
};

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
    // Tap on a notification shown while the app was open
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) return;
      try {
        _openFromPush(Map<String, dynamic>.from(jsonDecode(payload)));
      } catch (_) {}
    },
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

    if (message.data['type'] == jobPushType) {
      jobPushTick.value++; // refresh employee job list + badge
    }

    // Chat: no banner for the chat that is open on screen
    if (message.data['type'] == 'Chat' &&
        message.data['conversationId'] ==
            ChatService.instance.activeConversationId) {
      return;
    }

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
        payload: jsonEncode(message.data),
      );
    }
  });

  // Tap on a system notification while the app was in the background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _openFromPush(message.data);
  });

  // Tap on a notification that launched the app from closed. Wait for the
  // splash/role routing to finish first.
  final initial = await messaging.getInitialMessage();
  if (initial != null) {
    Future.delayed(const Duration(seconds: 3), () => _openFromPush(initial.data));
  }
}

/// Opens what a push is about: a chat (staff) or a job (employees).
Future<void> _openFromPush(Map<String, dynamic> data) async {
  if (data['type'] == 'Chat') {
    final convId = (data['conversationId'] ?? '').toString();
    final nav = navigatorKey.currentState;
    if (convId.isEmpty || nav == null || !ChatService.isStaff) return;
    if (ChatService.instance.activeConversationId == convId) return;
    nav.push(MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId)));
    return;
  }
  final bookingId = (data['bookingId'] ?? '').toString();
  if (data['type'] != jobPushType || bookingId.isEmpty) return;
  if (Globals.user == null || Globals.roleTitle != "Employee") return;
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  try {
    final res = await GeneralRepository().getBookingsForDriver();
    final all = [...res.assignedAssignments, ...res.completedAssignmnets];
    final match = all.where((p) => p.id == bookingId).toList();
    if (match.isNotEmpty) {
      Globals.bookingDriverResponse = match.first;
      nav.pushNamed(MyRoutes.bookingDetail);
    } else {
      // e.g. job removed from this employee: show the notifications list
      nav.pushNamed(MyRoutes.notificationsDriver);
    }
  } catch (_) {
    nav.pushNamed(MyRoutes.notificationsDriver);
  }
}

void navigateBasedOnRole() async {
  await SharedStorage.loadUser();

  Future.delayed(const Duration(seconds: 1), () {
    final nav = navigatorKey.currentState!;
    if (Globals.user != null) {
      if (Globals.roleTitle == "Employee") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => const DriverMainScreen()));
      } else if (Globals.roleTitle == "Administrator") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
      } else {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
      }
    } else {
      if (Globals.roleTitle == "Employee") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => const DriverMainScreen()));
      } else if (Globals.roleTitle == "Administrator") {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
      } else {
        nav.pushReplacement(MaterialPageRoute(builder: (_) => IntroScreen()));
      }
    }
  });
}
