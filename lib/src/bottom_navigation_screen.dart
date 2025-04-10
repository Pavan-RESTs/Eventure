import 'package:eventure/src/screens/event_management_screen.dart';
import 'package:eventure/src/screens/event_modification_page.dart';
import 'package:eventure/src/screens/venue_management_page.dart';
import 'package:eventure/src/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  List<Widget> screens = [
    EventManagementScreen(),
    EventModificationPage(),
    VenueManagementPage(),
  ];

  int currentIndex = 0; // Initialize currentIndex as a state variable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: screens[currentIndex],
        bottomNavigationBar: CustomBottomNavBar(
            currentIndex: currentIndex,
            onItemSelected: (index) {
              setState(() {
                currentIndex = index;
              });
            }));
  }
}
