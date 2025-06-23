import 'package:flutter/material.dart';
import 'notification_ui.dart';
import 'container.dart';
import 'profile.dart';

class Navbar extends StatelessWidget {
  final int currentIndex;

  const Navbar({
    super.key,
    required this.currentIndex,
  });

  void _navigateTo(BuildContext context, int index) {
    if (index == currentIndex) return; 

    Widget page;
    switch (index) {
      case 0:
        page = const NotificationUI();
        break;
      case 1:
        page = const ContainerPage();
        break;
      case 2:
        page = const ProfilePage();
        break;
      default:
        page = const NotificationUI();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _navigateTo(context, index),
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey[600],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Containers',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
