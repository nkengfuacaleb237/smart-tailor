import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'feed_screen.dart';
import 'my_catalogue_screen.dart';
import 'my_looks_screen.dart';
import 'measurements_screen.dart';
import 'profile_screen.dart';
import 'tailor_dashboard_screen.dart';
import 'tailor_looks_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTailor = appState.isTailor;

    final screens = isTailor
      ? [
          const FeedScreen(),
          const TailorDashboardScreen(),
          const TailorLooksScreen(),
          const ProfileScreen(),
        ]
      : [
          const FeedScreen(),
          const MyCatalogueScreen(),
          const MyLooksScreen(),
          const MeasurementsScreen(),
          const ProfileScreen(),
        ];

    final items = isTailor
      ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'My Looks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile'),
        ]
      : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Saved'),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'My Looks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.straighten_outlined),
            activeIcon: Icon(Icons.straighten),
            label: 'Measure'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile'),
        ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B5E20),
        unselectedItemColor: const Color(0xFF8E8E93),
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: items,
      ),
    );
  }
}
