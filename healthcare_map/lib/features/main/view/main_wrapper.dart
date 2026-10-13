import 'package:flutter/material.dart';
import '../../dashboard/view/dashboard_screen.dart';
import '../../map/view/map_screen.dart';
import '../../history/view/history_screen.dart';
import '../../settings/view/settings_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainWrapperState>();
    state?.changeTab(index);
  }

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MapScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Bản đồ'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
