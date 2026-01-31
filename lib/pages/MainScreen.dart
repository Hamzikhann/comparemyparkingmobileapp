import 'package:flutter/material.dart';
import 'package:parkingapp/data/Globals.dart';
import 'package:parkingapp/pages/BookingsScreen.dart';
import 'package:parkingapp/pages/HomeScreen.dart';
import 'package:parkingapp/pages/PaymentHistoryScreen.dart';
import 'package:parkingapp/pages/SettingsScreen.dart';
import 'package:parkingapp/pages/admin/AdminHome.dart';
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
        BookingsScreen(),
        PaymentHistoryScreen(),
        SettingsScreen(),
      ];

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
        bottomNavigationBar: Custombottomnavbar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
