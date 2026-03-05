import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'add_asset_screen.dart';
import 'asset_list_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isAdmin; 
  const MainScreen({super.key, required this.isAdmin});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _widgetOptions {
    if (widget.isAdmin) {
      return [
        DashboardScreen(onNavigate: _onItemTapped, isAdmin: widget.isAdmin),
        const AddAssetScreen(),
        AssetListScreen(isAdmin: widget.isAdmin),
      ];
    } else {
      return [
        DashboardScreen(onNavigate: _onItemTapped, isAdmin: widget.isAdmin),
        AssetListScreen(isAdmin: widget.isAdmin), 
      ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    if (widget.isAdmin) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'หน้าหลัก'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 32), activeIcon: Icon(Icons.add_circle, size: 32), label: 'เพิ่ม'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'ครุภัณฑ์'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'หน้าหลัก'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'ครุภัณฑ์'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1D4ED8),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}