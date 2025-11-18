import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:life_timerz/notification_service.dart';

class AddTaskListPage extends StatefulWidget {
  final bool showPinnedOnly;
  final ValueNotifier<String> selectedSort;

  const AddTaskListPage({
    super.key,
    required this.showPinnedOnly,
    required this.selectedSort,
  });

  @override
  State<AddTaskListPage> createState() => _AddTaskListPageState();
}

class _AddTaskListPageState extends State<AddTaskListPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Set<String> _notifiedTaskIds = {};

  final ValueNotifier<List<_LocalTask>> _taskListNotifier =
      ValueNotifier<List<_LocalTask>>([]);

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("User not logged in!"));

    return Scaffold(
      backgroundColor: Colors.white,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('timers')
            .where('uid', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<_LocalTask> tasks = snapshot.data!.docs.map((doc) {
            return _LocalTask(
              id: doc.id,
              data: Map<String, dynamic>.from(
                doc.data() as Map<String, dynamic>,
              ),
              ref: doc.reference,
            );
          }).toList();

          /// apply same sorting/filter
          return ValueListenableBuilder<String>(
            valueListenable: widget.selectedSort,
            builder: (_, sortValue, __) {
              tasks = _applySortingAndFilter(tasks, sortValue);
              _taskListNotifier.value = tasks;
              _runNotificationTriggers(tasks);

              if (tasks.isEmpty) {
                return Center(
                  child: Text(
                    widget.showPinnedOnly
                        ? "No pinned tasks yet!"
                        : "No tasks yet! Add one.",
                  ),
                );
              }

              // Before building list, run notification triggers on current local tasks
              _runNotificationTriggers(tasks);

              return ValueListenableBuilder<List<_LocalTask>>(
                valueListenable: _taskListNotifier,
                builder: (_, taskList, __) {
                  return ListView.builder(
                    itemCount: taskList.length,
                    itemBuilder: (_, index) {
                      final t = taskList[index];
                      final timer = t.data;
                      final title = timer['title'] ?? '';
                      final category = timer['category'] ?? '';
                      final datetimeRaw = timer['datetime'];
                      final datetime = (datetimeRaw is Timestamp)
                          ? datetimeRaw.toDate()
                          : (datetimeRaw is DateTime
                                ? datetimeRaw
                                : DateTime.now());
                      final isPinned = timer['isPinned'] ?? false;
                      final isCompleted = timer['isCompleted'] ?? false;

                      return Dismissible(
                        key: Key(t.id),
                        background: _swipeLeftBackground(),
                        secondaryBackground: _swipeRightBackground(),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            _markTaskCompletedLocally(t.id);
                            await t.ref.update({
                              'isCompleted': true,
                              'completedAt': FieldValue.serverTimestamp(),
                            });
                            return false; // keep item
                          } else if (direction == DismissDirection.endToStart) {
                            _removeTaskLocallyAt(index);
                            await t.ref.delete();
                            return true; // dismiss UI
                          }
                          return false;
                        },
                        child: _buildTaskTile(
                          t,
                          title,
                          category,
                          datetime,
                          isPinned,
                          isCompleted,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _swipeLeftBackground() => Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 20),
    color: Colors.green,
    child: const Icon(
      Icons.check_circle_outline,
      color: Colors.white,
      size: 28,
    ),
  );

  Widget _swipeRightBackground() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    color: Colors.red,
    child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
  );

  Widget _buildTaskTile(
    _LocalTask t,
    String title,
    String category,
    DateTime datetime,
    bool isPinned,
    bool isCompleted,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6),
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
                      key: ValueKey(t.id),
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
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned ? Colors.blue : Colors.grey,
            ),
            onPressed: () async {
              _togglePinLocally(t.id);
              await t.ref.update({'isPinned': !(t.data['isPinned'] ?? false)});
            },
          ),
        ],
      ),
    );
  }

  /// Run notification triggers on the local view of tasks (keeps original logic).
  Future<void> _runNotificationTriggers(List<_LocalTask> tasks) async {
    final now = DateTime.now();
    for (var t in tasks) {
      final data = t.data;
      final id = t.id;
      final title = data['title'] ?? 'Untitled Task';
      final datetimeDynamic = data['datetime'];

      DateTime datetime;
      if (datetimeDynamic is Timestamp) {
        datetime = datetimeDynamic.toDate();
      } else if (datetimeDynamic is DateTime) {
        datetime = datetimeDynamic;
      } else {
        // If malformed, skip
        continue;
      }
      final isCompleted = data['isCompleted'] ?? false;
      final diff = datetime.difference(now);

      String timeLeft() {
        if (diff.inDays >= 1) {
          return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} left";
        } else if (diff.inHours >= 1) {
          return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} left";
        } else if (diff.inMinutes > 0) {
          return "${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} left";
        } else {
          return "Due now!";
        }
      }

      final isCompletedNotificationSent =
          data['isCompletedNotificationSent'] ?? false;

      if (isCompleted &&
          !isCompletedNotificationSent &&
          !_notifiedTaskIds.contains("$id-completed")) {
        _notifiedTaskIds.add("$id-completed");
        NotificationService.showNotification(
          title: "Task Completed!",
          body: "Your task '$title' has been completed.",
        );
        // update Firestore to mark notification sent (fire-and-forget)
        t.ref.update({'isCompletedNotificationSent': true});
      }

      if (!isCompleted &&
          diff.inMinutes <= 60 &&
          diff.inMinutes > 0 &&
          data['isOneHourNotificationSent'] != true) {
        _notifiedTaskIds.add("$id-hourleft");
        NotificationService.showNotification(
          title: "${timeLeft()}",
          body: "Your task '$title' is due in less than 1 hour!",
        );
        // Save Firestore flag so it never repeats
        await t.ref.update({'isOneHourNotificationSent': true});
      }

      if (!isCompleted &&
          diff.inHours <= 24 &&
          diff.inHours > 1 &&
          data['isHourBeforeNotificationSent'] != true) {
        _notifiedTaskIds.add("$id-dayleft");
        NotificationService.showNotification(
          title: "⏳ $title - ${timeLeft()}",
          body: "Your task '$title' is due in ${timeLeft()}. Keep going!",
        );
        await t.ref.update({'isHourBeforeNotificationSent': true});
      }
    }
  }

  // LOCAL UI UPDATES (using ValueNotifier)
  // Mark a task complted globally(UI and firebase) both
  void _markTaskCompletedLocally(String id) {
    final current = List<_LocalTask>.from(_taskListNotifier.value);
    final idx = current.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updatedMap = Map<String, dynamic>.from(current[idx].data);
      updatedMap['isCompleted'] = true;
      updatedMap['completedAt'] = FieldValue.serverTimestamp();
      current[idx] = current[idx].copyWith(data: updatedMap);
      _taskListNotifier.value = current;
    }
  }

  // remove /delete tasks globally(UI and firebase) both
  void _removeTaskLocallyAt(int index) {
    final current = List<_LocalTask>.from(_taskListNotifier.value);
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      _taskListNotifier.value = current;
    }
  }

  // Toggle pin/unpin globally
  void _togglePinLocally(String id) {
    final current = List<_LocalTask>.from(_taskListNotifier.value);
    final idx = current.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updatedMap = Map<String, dynamic>.from(current[idx].data);
      updatedMap['isPinned'] = !(updatedMap['isPinned'] ?? false);
      current[idx] = current[idx].copyWith(data: updatedMap);
      _taskListNotifier.value = current;
    }
  }

  // Sorting & Filtering (adapted to _LocalTask)
  List<_LocalTask> _applySortingAndFilter(
    List<_LocalTask> docs,
    String sortValue,
  ) {
    // Separate active & completed
    List<_LocalTask> activeTasks = docs
        .where((e) => _parseBool(e.data['isCompleted']) == false)
        .toList();
    List<_LocalTask> completedTasks = docs
        .where((e) => _parseBool(e.data['isCompleted']) == true)
        .toList();

    // Sorting active tasks
    switch (widget.selectedSort.value) {
      case 'Newest':
        activeTasks.sort(
          (a, b) => _getDate(
            b.data['createdAt'] ?? b.data['datetime'],
          ).compareTo(_getDate(a.data['createdAt'] ?? a.data['datetime'])),
        );
        break;

      case 'Soonest':
        activeTasks.sort(
          (a, b) => _getDate(
            a.data['datetime'],
            fallback: true,
          ).compareTo(_getDate(b.data['datetime'], fallback: true)),
        );
        break;

      case 'Title name':
        activeTasks.sort(
          (a, b) => (a.data['title'] ?? '').toString().toLowerCase().compareTo(
            (b.data['title'] ?? '').toString().toLowerCase(),
          ),
        );
        break;

      case 'Category name':
        activeTasks.sort(
          (a, b) => (a.data['category'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b.data['category'] ?? '').toString().toLowerCase()),
        );
        break;

      case 'Longest':
        final now = DateTime.now();
        activeTasks.sort(
          (a, b) => _getDate(b.data['datetime'])
              .difference(now)
              .compareTo(_getDate(a.data['datetime']).difference(now)),
        );
        break;
    }

    // Sort completed tasks (latest completed first)
    completedTasks.sort(
      (a, b) => _getDate(
        b.data['completedAt'] ?? b.data['datetime'],
      ).compareTo(_getDate(a.data['completedAt'] ?? a.data['datetime'])),
    );

    List<_LocalTask> merged = [...activeTasks, ...completedTasks];

    if (widget.showPinnedOnly) {
      merged = merged.where((e) => e.data['isPinned'] == true).toList();
    }

    return merged;
  }

  // Helpers
  bool _parseBool(dynamic v) => v == true || v == 'true' || v == 1 || v == '1';

  DateTime _getDate(dynamic v, {bool fallback = false}) {
    if (v == null) {
      return fallback
          ? DateTime.fromMillisecondsSinceEpoch(9999999999999)
          : DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ??
        (fallback
            ? DateTime.fromMillisecondsSinceEpoch(9999999999999)
            : DateTime.fromMillisecondsSinceEpoch(0));
  }
}

/// Local lightweight model for tracking documents in UI without depending on QueryDocumentSnapshot
class _LocalTask {
  final String id;
  final Map<String, dynamic> data;
  final DocumentReference ref;

  _LocalTask({required this.id, required this.data, required this.ref});

  _LocalTask copyWith({
    String? id,
    Map<String, dynamic>? data,
    DocumentReference? ref,
  }) {
    return _LocalTask(
      id: id ?? this.id,
      data: data ?? Map<String, dynamic>.from(this.data),
      ref: ref ?? this.ref,
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
  final ValueNotifier<String> _remainingNotifier = ValueNotifier<String>('');
  bool _hasMarkedCompleted = false;

  @override
  void initState() {
    super.initState();
    // Keep the daily reminder call as before (will only schedule once per widget instance)
    NotificationService.scheduleDailyReminder(
      title: "Daily Reminder 🕘",
      body: "You have tasks scheduled today. Let's get started!",
      hour: 9,
      minute: 0,
    );

    _updateRemaining(); // initial
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  Future<void> _updateRemaining() async {
    if (!mounted) return;

    if (widget.isCompleted) {
      _remainingNotifier.value = "Completed!";
      _timer?.cancel();
      return;
    }

    final now = DateTime.now();
    final diff = widget.targetTime.difference(now);

    if (diff.isNegative) {
      _remainingNotifier.value = "Completed!";
      _timer?.cancel();

      // Avoid repeating the update if already done
      if (!_hasMarkedCompleted) {
        _hasMarkedCompleted = true;
        // Best-effort: check for doc ID from key if available and update Firestore
        final docId = (widget.key is ValueKey)
            ? (widget.key as ValueKey).value
            : null;
        if (docId != null) {
          try {
            await FirebaseFirestore.instance
                .collection('timers')
                .doc(docId.toString())
                .update({
                  'isCompleted': true,
                  'completedAt': FieldValue.serverTimestamp(),
                });
          } catch (_) {
            // ignore write errors silently (or optionally log)
          }
        }
      }
      return;
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    _remainingNotifier.value =
        "$days days, $hours hours, $minutes minutes, $seconds seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _remainingNotifier,
      builder: (context, remaining, _) {
        return Text(
          remaining,
          style: TextStyle(
            color: widget.isCompleted ? Colors.green : Colors.black,
            fontSize: 12,
            fontWeight: widget.isCompleted
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        );
      },
    );
  }
}
