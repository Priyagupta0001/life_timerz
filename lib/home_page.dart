import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:life_timerz/Profile_page.dart';
import 'package:life_timerz/addtasklist_page.dart';
import 'package:life_timerz/createnewtimer_page.dart';
import 'package:life_timerz/customappbar.dart';
import 'package:life_timerz/custombottomnavbar.dart';
import 'package:life_timerz/notification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:life_timerz/notification_service.dart';

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

  String _selectedSort = 'Soonest';
  final List<String> _sortOptions = [
    'Newest',
    'Title name',
    'Category name',
    'Longest',
    'Soonest',
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.initializeNotification();
    FirebaseAuth.instance.authStateChanges().listen((currentUser) {
      setState(() {
        user = currentUser;
      });
    });
  }

  //bottomnav tap
  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() {
      if (index == 1) {
        _showPinnedOnly = false; //show all tasks
      }
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  //edit tasks
  void _showEditAlert(String docId, Map<String, dynamic> task) {
    String title = task['title'];
    DateTime currentDateTime = (task['datetime'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 50,
            vertical: 18,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Edit Task",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  "Title",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  "Time:",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                CountdownText(targetTime: currentDateTime),
                const SizedBox(height: 30),

                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateNewTimerPage(
                            isEditing: true,
                            docId: docId,
                            existingTitle: title,
                            existingDateTime: currentDateTime,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 27, 80, 240),
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "EDIT",
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 1
          ? CustomAppBar(
              title: _titles[_selectedIndex],
              //sorting dropdown
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: DropdownButton<String>(
                    icon: const Icon(Icons.sort_outlined, size: 30, color: Colors.black),
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSort = newValue!;
                        print("Sort changed to: $_selectedSort");
                      });
                    },
                    items: _sortOptions.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: _selectedSort == value
                                ? Colors.blue[700]
                                : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    menuMaxHeight: 700,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ],
              backgroundColor: const Color.fromARGB(255, 243, 231, 230),
            )
          : CustomAppBar(
              title: _titles[_selectedIndex],
              backgroundColor: const Color.fromARGB(255, 252, 237, 236),
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
                                          226,
                                          188,
                                          223,
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
                                  _showPinnedOnly = false;
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
                                        _showPinnedOnly = false;
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
                                        final isCompleted =
                                            task['isCompleted'] ?? false;

                                        return Dismissible(
                                          key: ValueKey(docs[index].id),
                                          background: Container(
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.only(
                                              left: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            ),
                                          ),
                                          secondaryBackground: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                          ),
                                          confirmDismiss: (direction) async {
                                            if (direction ==
                                                DismissDirection.startToEnd) {
                                              // Mark completed
                                              await FirebaseFirestore.instance
                                                  .collection('timers')
                                                  .doc(docs[index].id)
                                                  .update({
                                                    'isCompleted': true,
                                                  });
                                              return false; // don't remove from list immediately
                                            } else if (direction ==
                                                DismissDirection.endToStart) {
                                              // Delete task
                                              await FirebaseFirestore.instance
                                                  .collection('timers')
                                                  .doc(docs[index].id)
                                                  .delete();
                                              return true; // remove from list
                                            }
                                            return false;
                                          },
                                          child: GestureDetector(
                                            onTap: () => _showEditAlert(
                                              docs[index].id,
                                              task,
                                            ),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 14,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.1),
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
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "${task['category']} - ${task['title']}",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.access_time,
                                                              color: Colors
                                                                  .black87,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            CountdownText(
                                                              key: ValueKey(
                                                                docs[index].id,
                                                              ),
                                                              targetTime:
                                                                  datetime,
                                                              isCompleted:
                                                                  isCompleted,
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
                                            ),
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
              child: AddTaskListPage(
                showPinnedOnly: _showPinnedOnly,
                selectedSort: _selectedSort,
              ),
            )
          : _selectedIndex == 2
          ? const ProfilePage()
          : NotificationPage(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("added task");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNewTimerPage(
                isEditing: false,
                existingTitle: '',
                existingDateTime: null,
              ),
            ),
          );
        },
        backgroundColor: Color.fromARGB(255, 32, 82, 233),
        shape: CircleBorder(),
        child: Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class CountdownText extends StatefulWidget {
  final DateTime targetTime;
  final bool isCompleted;

  const CountdownText({
    super.key,
    required this.targetTime,
    this.isCompleted = false,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  String _remaining = "";

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  void _updateRemaining() {
    if (!mounted) return;

    if (widget.isCompleted) {
      setState(() => _remaining = "Completed!");
      _timer?.cancel();
      return;
    }

    final now = DateTime.now();
    final diff = widget.targetTime.difference(now);

    if (diff.isNegative) {
      setState(() => _remaining = "Completed!");
      _timer?.cancel();
    } else {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      setState(() {
        _remaining =
            "$days days, $hours hours, $minutes minutes, $seconds seconds";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _remaining,
      style: TextStyle(
        color: widget.isCompleted ? Colors.green : Colors.black,
        fontSize: 12,
        fontWeight: widget.isCompleted ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
