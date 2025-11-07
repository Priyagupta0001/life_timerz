import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:life_timerz/Profile_page.dart';
import 'package:life_timerz/addtasklist_page.dart';
import 'package:life_timerz/createnewtimer_page.dart';
import 'package:life_timerz/notification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;

  bool _showPinnedOnly = false;

  int _selectedIndex = 0;
  final List<String> _titles = ["Home", "Task", "Profile", "Notification"];

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((currentUser) {
      setState(() {
        user = currentUser;
      });
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  String getRemainingTime(DateTime targetTime) {
    final now = DateTime.now();
    final diff = targetTime.difference(now);
    if (diff.isNegative) return "Time's up!";
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    return "$d days, $h hours, $m minutes";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      //APpbar - hide taskpage
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

      body: _selectedIndex == 0
          ? (user == null
                ? const Center(child: Text("User not logged in!"))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top counts row
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('timers')
                              .where('uid', isEqualTo: user?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final allTasks = snapshot.data!.docs;
                            final pinnedTasks = allTasks
                                .where(
                                  (doc) =>
                                      (doc.data()
                                          as Map<
                                            String,
                                            dynamic
                                          >)['isPinned'] ==
                                      true,
                                )
                                .toList();

                            return Row(
                              children: [
                                //Pintask Container
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showPinnedOnly = true;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          255,
                                          230,
                                          253,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(15),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.push_pin_outlined,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${pinnedTasks.length}",
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const Text(
                                                "Pin Task",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                //Total Task Container
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showPinnedOnly = false;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          230,
                                          237,
                                          255,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(15),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.task_alt_outlined,
                                              color: Color.fromARGB(
                                                255,
                                                32,
                                                82,
                                                233,
                                              ),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${allTasks.length}",
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const Text(
                                                "Total Task",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        //Pinnedtasks Head
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _showPinnedOnly ? "Pin Tasks" : "All Tasks",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = 1;
                                });
                              },
                              child: Row(
                                children: [
                                  const Text(
                                    "view all",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color.fromARGB(255, 8, 64, 233),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedIndex = 1;
                                      });
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        8,
                                        64,
                                        233,
                                      ),
                                      radius: 10,
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Pinnedtasks List
                        Expanded(
                          child: user == null
                              ? const Center(child: Text("User not logged in!"))
                              : StreamBuilder<QuerySnapshot>(
                                  stream: _showPinnedOnly
                                      ? FirebaseFirestore.instance
                                            .collection('timers')
                                            .where('uid', isEqualTo: user?.uid)
                                            .where('isPinned', isEqualTo: true)
                                            .orderBy(
                                              'datetime',
                                              descending: false,
                                            )
                                            .snapshots()
                                      : FirebaseFirestore.instance
                                            .collection('timers')
                                            .where('uid', isEqualTo: user?.uid)
                                            .orderBy(
                                              'datetime',
                                              descending: false,
                                            )
                                            .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Text("Error: ${snapshot.error}"),
                                      );
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          "No pinned tasks yet!",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      );
                                    }

                                    final docs = snapshot.data!.docs;

                                    return ListView.builder(
                                      itemCount: docs.length,
                                      itemBuilder: (context, index) {
                                        final task =
                                            docs[index].data()
                                                as Map<String, dynamic>;
                                        final title = task['title'] ?? '';
                                        final category = task['category'] ?? '';
                                        final datetimeRaw = task['datetime'];
                                        final datetime =
                                            datetimeRaw is Timestamp
                                            ? datetimeRaw.toDate()
                                            : DateTime.now();

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 6,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "$category - $title",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          color: Colors.black,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          getRemainingTime(
                                                            datetime,
                                                          ),
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.push_pin,
                                                color: const Color.fromARGB(
                                                  255,
                                                  32,
                                                  82,
                                                  233,
                                                ),
                                                size: 22,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ))
          : _selectedIndex == 1
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: AddTaskListPage(showPinnedOnly: _showPinnedOnly),
            )
          : _selectedIndex == 2
          ? const ProfilePage()
          : const NotificationPage(),

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
