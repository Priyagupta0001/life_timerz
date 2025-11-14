import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:life_timerz/notification_service.dart';

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
  final User? user = FirebaseAuth.instance.currentUser;
  final Set<String> _notifiedTaskIds = {};

  // Local notifier that holds the tasks we render (keeps immediate UI updates)
  final ValueNotifier<List<_LocalTask>> _taskListNotifier =
      ValueNotifier<List<_LocalTask>>([]);

  // Optional: keep stream subscription reference if you want to cancel later
  StreamSubscription<QuerySnapshot>? _snapshotSub;

  @override
  void initState() {
    super.initState();

    if (user != null) {
      _snapshotSub = FirebaseFirestore.instance
          .collection('timers')
          .where('uid', isEqualTo: user!.uid)
          .snapshots()
          .listen((snapshot) {
            // Convert to local tasks
            List<_LocalTask> incoming = snapshot.docs
                .map(
                  (doc) => _LocalTask(
                    id: doc.id,
                    data: Map<String, dynamic>.from(
                      doc.data() as Map<String, dynamic>,
                    ),
                    ref: doc.reference,
                  ),
                )
                .toList();

            // Apply sorting/filtering exactly as before (but on _LocalTask list)
            incoming = _applySortingAndFilter(incoming);

            _taskListNotifier.value = incoming;
          });
    }
  }

  @override
  void dispose() {
    _snapshotSub?.cancel();
    _taskListNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("User not logged in!"));

    return Scaffold(
      backgroundColor: Colors.white,
      body: ValueListenableBuilder<List<_LocalTask>>(
        valueListenable: _taskListNotifier,
        builder: (context, tasks, _) {
          // If notifier is empty it may mean no data yet or no tasks
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

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final t = tasks[index];
              final timer = t.data;
              final title = timer['title'] ?? '';
              final category = timer['category'] ?? '';
              final datetimeRaw = timer['datetime'];
              final datetime = (datetimeRaw is Timestamp)
                  ? datetimeRaw.toDate()
                  : (datetimeRaw is DateTime ? datetimeRaw : DateTime.now());
              final isPinned = timer['isPinned'] ?? false;
              final isCompleted = timer['isCompleted'] ?? false;

              return Dismissible(
                key: Key(t.id),
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
                    // COMPLETE: optimistic local update + update Firestore
                    _markTaskCompletedLocally(t.id);
                    await t.ref.update({
                      'isCompleted': true,
                      'completedAt': FieldValue.serverTimestamp(),
                    });
                    return false; // don't dismiss visually (we only mark completed)
                  } else if (direction == DismissDirection.endToStart) {
                    // DELETE: optimistic local removal + delete in Firestore
                    _removeTaskLocallyAt(index);
                    await t.ref.delete();
                    return true; // allow dismiss animation
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
                          color: isPinned
                              ? const Color.fromARGB(255, 32, 82, 233)
                              : Colors.grey,
                          size: 22,
                        ),
                        onPressed: () async {
                          // Toggle pin locally and in Firestore
                          _togglePinLocally(t.id);
                          await t.ref.update({
                            'isPinned': !(t.data['isPinned'] ?? false),
                          });
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

  /// Run notification triggers on the local view of tasks (keeps original logic).
  Future<void> _runNotificationTriggers(List<_LocalTask> tasks) async {
    final now = DateTime.now();
    for (var t in tasks) {
      final data = t.data;
      final id = t.id;
      final title = data['title'] ?? 'Untitled Task';
      final datetimeDynamic = data['datetime'];
      DateTime datetime;
      if (datetimeDynamic is Timestamp)
        datetime = datetimeDynamic.toDate();
      else if (datetimeDynamic is DateTime)
        datetime = datetimeDynamic;
      else {
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

  // Replace the entire local list (used by stream)
  void _replaceAllLocalTasks(List<_LocalTask> newList) {
    _taskListNotifier.value = newList;
  }

  // Mark a task completed in local notifier (without setState)
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

  // Remove a task at given index locally
  void _removeTaskLocallyAt(int index) {
    final current = List<_LocalTask>.from(_taskListNotifier.value);
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      _taskListNotifier.value = current;
    }
  }

  // Toggle pin locally
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

  @override
  void didUpdateWidget(covariant AddTaskListPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedSort != widget.selectedSort ||
        oldWidget.showPinnedOnly != widget.showPinnedOnly) {
      final sorted = _applySortingAndFilter(_taskListNotifier.value);
      _taskListNotifier.value = sorted;
    }
  }

  // Sorting & Filtering (adapted to _LocalTask)
  List<_LocalTask> _applySortingAndFilter(List<_LocalTask> docs) {
    // Apply initial parsing and separation into active/completed
    List<_LocalTask> activeTasks = [];
    List<_LocalTask> completedTasks = [];

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
      final data = doc.data;
      final raw = data['isCompleted'];
      final isCompleted = parseIsCompleted(raw);
      if (isCompleted) {
        completedTasks.add(doc);
      } else {
        activeTasks.add(doc);
      }
    }

    DateTime _getDate(dynamic v, {bool farFutureIfNull = false}) {
      if (v == null) {
        return farFutureIfNull
            ? DateTime.fromMillisecondsSinceEpoch(9999999999999)
            : DateTime.fromMillisecondsSinceEpoch(0);
      }
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ??
          (farFutureIfNull
              ? DateTime.fromMillisecondsSinceEpoch(9999999999999)
              : DateTime.fromMillisecondsSinceEpoch(0));
    }

    switch (widget.selectedSort) {
      case 'Newest':
        activeTasks.sort((a, b) {
          final aData = a.data;
          final bData = b.data;
          final aTime = aData['createdAt'] ?? aData['datetime'];
          final bTime = bData['createdAt'] ?? bData['datetime'];
          return _getDate(bTime).compareTo(_getDate(aTime));
        });
        break;

      case 'Soonest':
        activeTasks.sort((a, b) {
          final aData = a.data;
          final bData = b.data;
          return _getDate(
            aData['datetime'],
            farFutureIfNull: true,
          ).compareTo(_getDate(bData['datetime'], farFutureIfNull: true));
        });
        break;

      case 'Title name':
        activeTasks.sort((a, b) {
          final aTitle = (a.data['title'] ?? '').toString();
          final bTitle = (b.data['title'] ?? '').toString();
          return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
        });
        break;

      case 'Category name':
        activeTasks.sort((a, b) {
          final aCat = (a.data['category'] ?? '').toString();
          final bCat = (b.data['category'] ?? '').toString();
          return aCat.toLowerCase().compareTo(bCat.toLowerCase());
        });
        break;

      case 'Longest':
        activeTasks.sort((a, b) {
          final now = DateTime.now();
          final aTime = _getDate(a.data['datetime']);
          final bTime = _getDate(b.data['datetime']);
          return bTime.difference(now).compareTo(aTime.difference(now));
        });
        break;

      default:
        break;
    }

    completedTasks.sort((a, b) {
      final aDate = a.data['completedAt'] ?? a.data['datetime'];
      final bDate = b.data['completedAt'] ?? b.data['datetime'];
      return _getDate(bDate).compareTo(_getDate(aDate));
    });

    // Apply pinned filter if needed
    List<_LocalTask> merged = [...activeTasks, ...completedTasks];
    if (widget.showPinnedOnly) {
      merged = merged.where((doc) => doc.data['isPinned'] == true).toList();
    }

    return merged;
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
