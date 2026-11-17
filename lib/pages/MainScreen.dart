import 'package:flutter/material.dart';
import 'package:parkingapp/chat/chat_service.dart';
import 'package:parkingapp/chat/ui/chats_screen.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/pages/BookingsScreen.dart';
import 'package:parkingapp/pages/HomeScreen.dart';
import 'package:parkingapp/pages/PaymentHistoryScreen.dart';
import 'package:parkingapp/pages/SettingsScreen.dart';
import 'package:parkingapp/pages/admin/AdminHome.dart';
import 'package:parkingapp/pages/admin/AdminBookingsScreen.dart';
import 'package:parkingapp/pages/admin/AdminPaymentsScreen.dart';
import 'package:parkingapp/pages/admin/AdminUsersScreen.dart';
import 'package:parkingapp/widgets/CustomBottomNavBar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  bool get _isAdmin => Globals.user?.roleTitle.toLowerCase() == 'administrator';

  List<Widget> get _screens => [
        _isAdmin ? const Adminhome() : HomeScreen(),
        // Admins: paged lists of everyone's bookings/payments
        _isAdmin ? const AdminBookingsScreen() : BookingsScreen(),
        _isAdmin ? const AdminPaymentsScreen() : PaymentHistoryScreen(),
        if (_isAdmin) const AdminUsersScreen(asTab: true),
        if (_isAdmin) const ChatsScreen(), // admins chat with drivers
        SettingsScreen(),
      ];

  static const int _adminChatsTab = 4;

  List<NavBarItem> get _items => _isAdmin
      ? const [
          NavBarItem(label: "Home", svgPath: "assets/images/home.svg"),
          NavBarItem(label: "Bookings", svgPath: "assets/images/bookings.svg"),
          NavBarItem(label: "Payments", svgPath: "assets/images/wallets.svg"),
          NavBarItem(label: "Users", icon: Icons.people_outline),
          NavBarItem(label: "Chats", icon: Icons.chat_bubble_outline),
          NavBarItem(label: "Settings", svgPath: "assets/images/settings.svg"),
        ]
      : Custombottomnavbar.customerItems;

  @override
  void initState() {
    super.initState();
    if (_isAdmin) ChatService.instance.start();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you really want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _screens[_currentIndex],
        bottomNavigationBar: ListenableBuilder(
          listenable: ChatService.instance,
          builder: (context, _) => Custombottomnavbar(
            items: _items,
            currentIndex: _currentIndex,
            badges: _isAdmin
                ? {_adminChatsTab: ChatService.instance.totalUnread}
                : const {},
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
