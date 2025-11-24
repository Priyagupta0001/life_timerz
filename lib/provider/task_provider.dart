// ignore_for_file: curly_braces_in_flow_control_structures, library_private_types_in_public_api, unnecessary_cast

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:life_timerz/services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final User? user = FirebaseAuth.instance.currentUser;
  List<_LocalTask> _tasks = [];
  List<_LocalTask> get tasks => _tasks;

  bool showPinnedOnly = false;
  String selectedSort = 'Newest';
  final List<String> sortOptions = [
    'Newest',
    'Title name',
    'Category name',
    'Longest',
    'Soonest',
  ];

  final Set<String> _notifiedTaskIds = {};
  StreamSubscription? _taskStream;
  Timer? _timer;

  TaskProvider() {
    _init();
    _startCompletionChecker();
  }

  void _init() {
    if (user == null) return;

    _taskStream = FirebaseFirestore.instance
        .collection('timers')
        .where('uid', isEqualTo: user!.uid)
        .snapshots()
        .listen((snapshot) {
          _tasks = snapshot.docs.map((doc) {
            return _LocalTask(
              id: doc.id,
              data: Map<String, dynamic>.from(
                doc.data() as Map<String, dynamic>,
              ),
              ref: doc.reference,
            );
          }).toList();

          _runNotificationTriggers();
          notifyListeners();
        });
  }

  void setSort(String sort) {
    selectedSort = sort;

    notifyListeners();
  }

  void setShowPinnedOnly(bool show) {
    showPinnedOnly = show;

    notifyListeners();
  }

  /// Timer-based automatic completion check
  void _startCompletionChecker() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 5), (_) async {
      final now = DateTime.now();
      bool updated = false;

      for (var i = 0; i < _tasks.length; i++) {
        final t = _tasks[i];
        if (t.data['isCompleted'] == true) continue;

        final datetime = _parseDate(t.data['datetime']);
        if (datetime == null) continue; // ignore invalid dates
        if (datetime.isAfter(now)) continue; // future task → skip

        // mark task completed
        final updatedData = Map<String, dynamic>.from(t.data);
        updatedData['isCompleted'] = true;
        updatedData['completedAt'] = FieldValue.serverTimestamp();
        _tasks[i] = t.copyWith(data: updatedData);

        try {
          await t.ref.update(updatedData);
        } catch (_) {}

        updated = true;
      }

      if (updated) notifyListeners();
    });
  }

  Future<String?> togglePin(String id) async {
    final idx = _tasks.indexWhere((e) => e.id == id);
    if (idx == -1) return null;

    final updated = Map<String, dynamic>.from(_tasks[idx].data);
    updated['isPinned'] = !(updated['isPinned'] ?? false);
    _tasks[idx] = _tasks[idx].copyWith(data: updated);
    notifyListeners();

    try {
      await _tasks[idx].ref.update({'isPinned': updated['isPinned']});
      return updated['isPinned'] ? "Task pinned!" : "Task unpinned!";
    } catch (_) {
      return null;
    }
  }

  Future<String?> markCompleted(String id) async {
    final idx = _tasks.indexWhere((e) => e.id == id);
    if (idx == -1) return null;

    final updated = Map<String, dynamic>.from(_tasks[idx].data);
    updated['isCompleted'] = true;
    updated['completedAt'] = FieldValue.serverTimestamp();
    _tasks[idx] = _tasks[idx].copyWith(data: updated);
    notifyListeners();

    try {
      await _tasks[idx].ref.update(updated);
      return "Task marked completed!";
    } catch (_) {
      return null;
    }
  }

  Future<String?> deleteTask(int index) async {
    if (index < 0 || index >= _tasks.length) return null;

    final task = _tasks[index];
    _tasks.removeAt(index);
    notifyListeners();

    try {
      await task.ref.delete();
      return "Task deleted!";
    } catch (_) {
      return null;
    }
  }

  List<_LocalTask> get sortedTasks {
    List<_LocalTask> activeTasks = _tasks
        .where((e) => !(e.data['isCompleted'] ?? false))
        .toList();
    List<_LocalTask> completedTasks = _tasks
        .where((e) => e.data['isCompleted'] ?? false)
        .toList();

    // Apply sorting to activeTasks
    switch (selectedSort) {
      case 'Newest':
        activeTasks.sort(
          (a, b) =>
              (_parseDate(b.data['createdAt'] ?? b.data['datetime']) ??
                      DateTime.now())
                  .compareTo(
                    _parseDate(a.data['createdAt'] ?? a.data['datetime']) ??
                        DateTime.now(),
                  ),
        );
        break;
      case 'Soonest':
        activeTasks.sort(
          (a, b) => (_parseDate(a.data['datetime']) ?? DateTime.now())
              .compareTo(_parseDate(b.data['datetime']) ?? DateTime.now()),
        );
        break;
      case 'Title name':
        activeTasks.sort(
          (a, b) => (a.data['title'] ?? '').toLowerCase().compareTo(
            (b.data['title'] ?? '').toLowerCase(),
          ),
        );
        break;
      case 'Category name':
        activeTasks.sort(
          (a, b) => (a.data['category'] ?? '').toLowerCase().compareTo(
            (b.data['category'] ?? '').toLowerCase(),
          ),
        );
        break;
      case 'Longest':
        final now = DateTime.now();
        activeTasks.sort(
          (a, b) => (_parseDate(b.data['datetime']) ?? DateTime.now())
              .difference(now)
              .compareTo(
                (_parseDate(a.data['datetime']) ?? DateTime.now()).difference(
                  now,
                ),
              ),
        );
        break;
    }

    // Sort completed tasks
    completedTasks.sort(
      (a, b) =>
          (_parseDate(b.data['completedAt'] ?? b.data['datetime']) ??
                  DateTime.now())
              .compareTo(
                _parseDate(a.data['completedAt'] ?? a.data['datetime']) ??
                    DateTime.now(),
              ),
    );

    List<_LocalTask> allTasks = [...activeTasks, ...completedTasks];

    if (showPinnedOnly) {
      allTasks = allTasks.where((e) => e.data['isPinned'] == true).toList();
    }

    return allTasks;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  Future<void> _runNotificationTriggers() async {
    final now = DateTime.now();

    for (var t in _tasks) {
      final id = t.id;
      final title = t.data['title'] ?? 'Untitled Task';
      final datetime = _parseDate(t.data['datetime']);
      if (datetime == null) continue;

      final isCompleted = t.data['isCompleted'] ?? false;
      final diff = datetime.difference(now);

      // Completed notification
      if (isCompleted &&
          !(t.data['isCompletedNotificationSent'] ?? false) &&
          !_notifiedTaskIds.contains("$id-completed")) {
        _notifiedTaskIds.add("$id-completed");
        NotificationService.showNotification(
          title: "Task Completed!",
          body: "Your task '$title' has been completed.",
        );
        t.ref.update({'isCompletedNotificationSent': true});
      }

      // 1 hour left notification
      if (!isCompleted &&
          diff.inMinutes <= 60 &&
          diff.inMinutes > 0 &&
          !(t.data['isOneHourNotificationSent'] ?? false)) {
        _notifiedTaskIds.add("$id-hourleft");
        NotificationService.showNotification(
          title: "Task '$title' due soon!",
          body: "Less than 1 hour left!",
        );
        await t.ref.update({'isOneHourNotificationSent': true});
      }

      // 24 hours left notification
      if (!isCompleted &&
          diff.inHours <= 24 &&
          diff.inHours > 1 &&
          !(t.data['isHourBeforeNotificationSent'] ?? false)) {
        _notifiedTaskIds.add("$id-dayleft");
        NotificationService.showNotification(
          title: "$title - ${diff.inHours} hours left",
          body: "Keep going!",
        );
        await t.ref.update({'isHourBeforeNotificationSent': true});
      }
    }
  }

  _LocalTask? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskStream?.cancel();
    super.dispose();
  }
}

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
