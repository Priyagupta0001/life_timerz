import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Adjust height based on orientation
    final double iconSize = isLandscape ? 13.sp : 28.sp;
    final double fontSize = isLandscape ? 8.sp : 12.sp;

    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        backgroundColor: const Color.fromARGB(255, 246, 246, 255),
        selectedItemColor: const Color.fromARGB(255, 27, 120, 196),
        unselectedItemColor: Colors.black,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: fontSize),
        unselectedLabelStyle: TextStyle(fontSize: fontSize),
        elevation: 0,
        iconSize: iconSize,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            label: "Task",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: "Profile",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: "Notification",
          ),
        ],
      ),
    );
  }
}
