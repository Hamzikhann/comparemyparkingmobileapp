import 'package:flutter/material.dart';
import 'package:parkingapp/pages/BookingsScreen.dart';
import 'package:parkingapp/pages/HomeScreen.dart';
import 'package:parkingapp/pages/PaymentsScreen.dart';
import 'package:parkingapp/pages/SettingsScreen.dart';
import 'package:parkingapp/widgets/CustomBottomNavBar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingsScreen(),
    const PaymentsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
