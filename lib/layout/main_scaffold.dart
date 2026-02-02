import 'package:flutter/material.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/screens/home/home_screen.dart';
import 'package:da_project_1/screens/data/data_screen.dart';
import 'package:da_project_1/theme/da_colors.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DataScreen(),
  ];

  void _onItemTapped(int index) {
    /// LOGOUT
    if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: DAColors.white,
        selectedItemColor: DAColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 28,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}