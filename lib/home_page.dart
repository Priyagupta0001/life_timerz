import 'package:flutter/material.dart';
import 'package:life_timerz/Profile_page.dart';
import 'package:life_timerz/addtasklist_page.dart';
import 'package:life_timerz/createnewtimer_page.dart';
import 'package:life_timerz/notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text("Home", style: TextStyle(fontSize: 20))),
    AddTaskListPage(),
    ProfilePage(),
    NotificationPage(),
  ];

  final List<String> _titles = ["Home", "Task", "Profile", "Notification"];

  void _onItemTapped(int index) {
    if (index == 2) return;

    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: _selectedIndex == 1
          ? null
          : AppBar(
              backgroundColor: const Color.fromARGB(255, 246, 246, 255),
              automaticallyImplyLeading: false,
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),

      body: _pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("added task");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateNewTimerPage()),
          );
        },
        backgroundColor: Color.fromARGB(255, 32, 82, 233),
        shape: CircleBorder(),
        child: Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex >= 2
              ? _selectedIndex + 1
              : _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Color.fromARGB(255, 246, 246, 255),
          selectedItemColor: const Color.fromARGB(255, 27, 120, 196),
          unselectedItemColor: Colors.black,
          showUnselectedLabels: true,
          iconSize: 30,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_outlined),
              label: "Task",
            ),
            const BottomNavigationBarItem(icon: SizedBox.shrink(), label: ""),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined),
              label: "Profile",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label: "Notification",
            ),
          ],
        ),
      ),
    );
  }
}
