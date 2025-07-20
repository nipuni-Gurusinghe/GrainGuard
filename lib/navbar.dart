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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _navigateTo(context, index),
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF00ACC1), // Teal
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndex == 0 
                    ? const Color(0xFF00ACC1).withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00ACC1).withOpacity(0.2),
              ),
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndex == 1
                    ? const Color(0xFF00ACC1).withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: const Icon(Icons.inventory_2_outlined),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00ACC1).withOpacity(0.2),
              ),
              child: const Icon(Icons.inventory_2),
            ),
            label: 'Containers',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndex == 2
                    ? const Color(0xFF00ACC1).withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: const Icon(Icons.person_outline),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00ACC1).withOpacity(0.2),
              ),
              child: const Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}