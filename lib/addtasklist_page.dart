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
                  //.orderBy('datetime', descending: false)
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
                              .update({
                                'isCompleted': true,
                                'completedAt': FieldValue.serverTimestamp(),
                              });
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
                          vertical: 14,
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

    List<QueryDocumentSnapshot> activeTasks = [];
    List<QueryDocumentSnapshot> completedTasks = [];

    bool parseIsCompleted(dynamic raw) {
      if (raw == null) return false;
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final val = raw.toLowerCase().trim();
        return val == 'true' || val == '1' || val == 'yes';
      }
      return false;
    }

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final raw = data['isCompleted'];
      final isCompleted = parseIsCompleted(raw);
      print("Doc ${doc.id} => isCompleted=$isCompleted (raw=$raw)");

      if (isCompleted) {
        completedTasks.add(doc);
      } else {
        activeTasks.add(doc);
      }
    }

    switch (widget.selectedSort) {
      case 'Newest':
        activeTasks.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] ?? aData['datetime']);
          final bTime = (bData['createdAt'] ?? bData['datetime']);
          DateTime getDate(dynamic v) {
            if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
            if (v is Timestamp) return v.toDate();
            if (v is DateTime) return v;
            return DateTime.tryParse(v.toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
          }

          return getDate(bTime).compareTo(getDate(aTime));
        });
        break;

      case 'Soonest':
        activeTasks.sort((a, b) {
          DateTime getDate(dynamic v) {
            if (v == null) {
              return DateTime.fromMillisecondsSinceEpoch(9999999999999);
            }
            if (v is Timestamp) return v.toDate();
            if (v is DateTime) return v;
            return DateTime.tryParse(v.toString()) ??
                DateTime.fromMillisecondsSinceEpoch(9999999999999);
          }

          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          return getDate(
            aData['datetime'],
          ).compareTo(getDate(bData['datetime']));
        });
        break;

      case 'Title name':
        activeTasks.sort((a, b) {
          final aTitle = ((a.data() as Map<String, dynamic>)['title'] ?? '')
              .toString();
          final bTitle = ((b.data() as Map<String, dynamic>)['title'] ?? '')
              .toString();
          return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
        });
        break;

      case 'Category name':
        activeTasks.sort((a, b) {
          final aCategory =
              ((a.data() as Map<String, dynamic>)['category'] ?? '').toString();
          final bCategory =
              ((b.data() as Map<String, dynamic>)['category'] ?? '').toString();
          return aCategory.toLowerCase().compareTo(bCategory.toLowerCase());
        });
        break;

      case 'Longest':
        activeTasks.sort((a, b) {
          DateTime getDate(dynamic v) {
            if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
            if (v is Timestamp) return v.toDate();
            if (v is DateTime) return v;
            return DateTime.tryParse(v.toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
          }

          final now = DateTime.now();
          final aTime = getDate((a.data() as Map<String, dynamic>)['datetime']);
          final bTime = getDate((b.data() as Map<String, dynamic>)['datetime']);
          return bTime.difference(now).compareTo(aTime.difference(now));
        });
        break;
    }

    completedTasks.sort((a, b) {
      DateTime getDate(dynamic v) {
        if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return DateTime.tryParse(v.toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      return getDate(
        bData['completedAt'] ?? bData['datetime'],
      ).compareTo(getDate(aData['completedAt'] ?? aData['datetime']));
    });

    print("Active: ${activeTasks.length}, Completed: ${completedTasks.length}");
    return [...activeTasks, ...completedTasks];
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

  void _updateRemaining() async {
    if (!mounted) return;

    final now = DateTime.now();
    final diff = widget.targetTime.difference(now);

    if (diff.isNegative || widget.isCompleted) {
      setState(() => _remaining = "Completed!");
      _timer?.cancel();

      if (!widget.isCompleted) {
        final timers = FirebaseFirestore.instance.collection('timers');
        final docId = (widget.key is ValueKey)
            ? (widget.key as ValueKey).value
            : null;
        if (docId != null) {
          await timers.doc(docId.toString()).update({
            'isCompleted': true,
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return;
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    setState(() {
      _remaining =
          "$days days, $hours hours, $minutes minutes, $seconds seconds";
    });
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
