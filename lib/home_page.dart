import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:life_timerz/Profile_page.dart';
import 'package:life_timerz/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text("Home", style: TextStyle(fontSize: 20))),
    Center(child: Text("Tasks", style: TextStyle(fontSize: 20))),
    ProfilePage(),
    Center(child: Text("Notifications", style: TextStyle(fontSize: 20))),
  ];

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _selectedIndex == 2
          ? null
          : AppBar(
              automaticallyImplyLeading: false, //back button remove
              title: Text(
                "Home",
                style: TextStyle(
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
          currentIndex: _selectedIndex > 1
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
