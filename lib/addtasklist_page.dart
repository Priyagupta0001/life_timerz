import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTaskListPage extends StatefulWidget {
  final bool showPinnedOnly;
  final String selectedSort;

  const AddTaskListPage({
    super.key,
    required this.showPinnedOnly,
    required this.selectedSort,
  });

  @override
  State<AddTaskListPage> createState() => _AddTaskListPageState();
}

class _AddTaskListPageState extends State<AddTaskListPage> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: user == null
          ? const Center(child: Text("User not logged in!"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timers')
                  .where('uid', isEqualTo: user!.uid)
                  .orderBy('datetime', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Something went wrong. Please try again."),
                  );
                }

                var docs = snapshot.data!.docs;
                docs = _applySorting(docs);

                // Filter pinned tasks if required
                if (widget.showPinnedOnly) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['isPinned'] == true;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      widget.showPinnedOnly
                          ? "No pinned tasks yet!"
                          : "No tasks yet! Add one.",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
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
                    final isCompleted = timer['isCompleted'] ?? false;

                    return Dismissible(
                      key: Key(timerDoc.id),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Swipe Right → Mark as Completed
                          await FirebaseFirestore.instance
                              .collection('timers')
                              .doc(timerDoc.id)
                              .update({'isCompleted': true});
                          return false;
                        } else if (direction == DismissDirection.endToStart) {
                          // Swipe Left → Delete Task
                          await FirebaseFirestore.instance
                              .collection('timers')
                              .doc(timerDoc.id)
                              .delete();
                          return true;
                        }
                        return false;
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$category - $title",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      CountdownText(
                                        key: ValueKey(timerDoc.id),
                                        targetTime: datetime,
                                        isCompleted: isCompleted,
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

  List<QueryDocumentSnapshot> _applySorting(List<QueryDocumentSnapshot> docs) {
    print("Applying sort: ${widget.selectedSort}");
    switch (widget.selectedSort) {
      case 'Newest':
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['datetime'] as Timestamp;
          final bTime = bData['datetime'] as Timestamp;
          return bTime.compareTo(aTime); // Newest first
        });
        break;

      case 'Soonest':
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['datetime'] as Timestamp;
          final bTime = bData['datetime'] as Timestamp;
          return aTime.compareTo(bTime); // Soonest first
        });
        break;

      case 'Longest':
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['datetime'] as Timestamp;
          final bTime = bData['datetime'] as Timestamp;
          final now = DateTime.now();
          final aDiff = aTime.toDate().difference(now);
          final bDiff = bTime.toDate().difference(now);
          return bDiff.compareTo(aDiff); // Longest duration first
        });
        break;

      case 'Category name':
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCategory = (aData['category'] ?? '').toString().toLowerCase();
          final bCategory = (bData['category'] ?? '').toString().toLowerCase();
          return aCategory.compareTo(bCategory);
        });
        break;

      case 'Title name':
        print("title name");
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTitle = (aData['title'] ?? 'No Title')
              .toString()
              .toLowerCase();
          final bTitle = (bData['title'] ?? 'No Title')
              .toString()
              .toLowerCase();
          return aTitle.compareTo(bTitle);
        });
        break;
    }
    return docs;
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
        color: Colors.black,
        fontSize: 12,
        fontWeight: widget.isCompleted ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
