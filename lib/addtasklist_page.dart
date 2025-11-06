import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTaskListPage extends StatefulWidget {
  const AddTaskListPage({super.key});

  @override
  State<StatefulWidget> createState() => _AddTaskListPageState();
}

class _AddTaskListPageState extends State<AddTaskListPage> {
  User? user = FirebaseAuth.instance.currentUser;
  // delete timer
  Future<void> _deleteTimer(String id) async {
    try {
      await FirebaseFirestore.instance.collection('timers').doc(id).delete();
    } catch (e) {
      print("Error deleting timer: $e");
    }
  }

  // remaining time calculate
  String getRemainingTime(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);

    if (difference.isNegative) return "Time's up!";

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    return "$days days, $hours hours, $minutes minutes";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 246, 246, 255),
        automaticallyImplyLeading: false, //backbutton remove
        title: Text(
          "Task",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: user == null
          ? const Center(child: Text("User not logged in!"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timers')
                  .where('uid', isEqualTo: user!.uid)
                  .orderBy('datetime', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                print("Current user UID: ${user!.uid}");

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print("Firestore error: ${snapshot.error}");
                  return const Center(
                    child: Text("Something went wrong. Please try again."),
                  );
                }

                final docs = snapshot.data!.docs; //list k form m extrct data

                if (docs.isEmpty) {
                  return const Center(child: Text("No timers yet! Add one."));
                }

                print("Timers fetched: ${docs.length}");

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 0,
                  ),
                  itemBuilder: (context, index) {
                    final timerDoc = docs[index];
                    final timer = timerDoc.data() as Map<String, dynamic>;
                    final title = timer['title'] ?? '';
                    final category = timer['category'] ?? '';
                    final datetimeRaw = timer['datetime'];
                    final datetime = datetimeRaw is Timestamp
                        ? datetimeRaw.toDate()
                        : DateTime.now();
                    final isPinned = timer['isPinned'] ?? false;
                    return Dismissible(
                      key: Key(timerDoc.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.delete_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteTimer(timerDoc.id),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$category - $title",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        getRemainingTime(datetime),
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
                            IconButton(
                              icon: Icon(
                                isPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: isPinned
                                    ? const Color.fromARGB(255, 32, 82, 233)
                                    : Colors.grey,
                                size: 22,
                              ),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('timers')
                                    .doc(timerDoc.id)
                                    .update({'isPinned': !isPinned});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
