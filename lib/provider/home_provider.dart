import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:life_timerz/services/notification_service.dart';

class HomeProvider extends ChangeNotifier {
  User? user = FirebaseAuth.instance.currentUser;

  int selectedIndex = 0;
  bool showPinnedOnly = false;
  String selectedSort = 'Newest';

  final List<String> titles = ["Home", "Task", "Profile", "Notification"];

  final TextEditingController editController = TextEditingController();

  get taskList => null;

  void setEditText(String text) {
    editController.text = text;
    notifyListeners();
  }

  void initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((currentUser) {
      user = currentUser;
      notifyListeners();
    });
  }

  void onItemTapped(int index) {
    selectedIndex = index;
    showPinnedOnly = false; // reset pinned view when switching tabs
    notifyListeners();
  }

  void togglePinnedView(bool pinned) {
    showPinnedOnly = pinned;
    notifyListeners();
  }

  /// ---------------- FIRESTORE STREAMS ----------------
  Stream<QuerySnapshot> getAllTasks() {
    return FirebaseFirestore.instance
        .collection('timers')
        .where('uid', isEqualTo: user?.uid)
        .orderBy('datetime', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getPinnedTasks() {
    return FirebaseFirestore.instance
        .collection('timers')
        .where('uid', isEqualTo: user?.uid)
        .where('isPinned', isEqualTo: true)
        .orderBy('datetime', descending: false)
        .snapshots();
  }

  /// ---------------- TASK UPDATE / DELETE ----------------
  Future<void> updateTask(String taskId, String newTitle) async {
    if (taskId.isEmpty || newTitle.isEmpty) return;

    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'title': newTitle,
    });

    notifyListeners(); // important if you also maintain local state
  }

  Future<void> markTaskCompleted(String docId) async {
    await FirebaseFirestore.instance.collection('timers').doc(docId).update({
      'isCompleted': true,
    });

    await NotificationService.cancelNotificationById(docId.hashCode);
  }

  Future<void> deleteTask(String docId) async {
    await FirebaseFirestore.instance.collection('timers').doc(docId).delete();
  }
}
