import 'package:flutter/material.dart';

class Custombottomnavbar extends StatelessWidget {
  const Custombottomnavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF201A56),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: '',
        ),
      ],
    );
  }
}
