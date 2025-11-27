import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TimerProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fields previously in UI
  String _title = '';
  String _category = '';
  DateTime? _selectedDateTime;
  bool _isCountdown = false;

  // Getters
  String get title => _title;
  String get category => _category;
  DateTime? get selectedDateTime => _selectedDateTime;
  bool get isCountdown => _isCountdown;

  // Setters
  void setTitle(String val) {
    _title = val;
    notifyListeners();
  }

  void setCategory(String val) {
    _category = val;
    notifyListeners();
  }

  void setDateTime(DateTime val) {
    _selectedDateTime = val;
    notifyListeners();
  }

  void setCountdown(bool val) {
    _isCountdown = val;
    notifyListeners();
  }

  // Clear feilds
  void reset() {
    _title = '';
    _category = '';
    _selectedDateTime = null;
    _isCountdown = false;
    notifyListeners();
  }

  // Save / Update Timer
  Future<String> saveOrUpdateTimer({String? docId}) async {
    if (_title.trim().isEmpty) return "title-empty";
    if (_category.trim().isEmpty) return "category-empty";
    if (_selectedDateTime == null) return "date-empty";

    try {
      _isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "no-user";

      final data = {
        "uid": user.uid,
        "title": _title.trim(),
        "category": _category,
        "datetime": Timestamp.fromDate(_selectedDateTime!),
        "isCountDown": _isCountdown,
      };

      bool newCompletedStatus = false;
      final now = DateTime.now();
      if (docId != null) {
        final docSnap = await FirebaseFirestore.instance
            .collection("timers")
            .doc(docId)
            .get();
        final existingCompleted = docSnap['isCompleted'] ?? false;

        // Agar existing task manually completed hai
        // lekin naya datetime future me hai, to countdown wapas start karenge
        if (existingCompleted && _selectedDateTime!.isAfter(now)) {
          newCompletedStatus = false; // countdown wapas
        } else {
          newCompletedStatus = existingCompleted;
        }

        await FirebaseFirestore.instance
            .collection("timers")
            .doc(docId)
            .update({
              ...data,
              "updatedAt": FieldValue.serverTimestamp(),
              "isCompleted": newCompletedStatus,
            });
        _isLoading = false;
        notifyListeners();
        return "updated";
      } else {
        await FirebaseFirestore.instance.collection("timers").add({
          ...data,
          "createdAt": FieldValue.serverTimestamp(),
          "isPinned": false,
        });
        _isLoading = false;
        notifyListeners();
        return "created";
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "error";
    }
  }

  // Initialize values if editing
  void initialize({
    String? title,
    String? category,
    DateTime? dateTime,
    bool? isCountdown,
    bool? isCompleted,
  }) {
    _title = title ?? '';
    _category = category ?? 'Personal';
    _selectedDateTime = dateTime;
    _isCountdown = isCountdown ?? false;
    
    final now = DateTime.now();

    if (_selectedDateTime != null) {
      if (isCompleted == true && _selectedDateTime!.isAfter(now)) {
        // Agar task complete tha lekin naya datetime future me hai
        _isCountdown = true; // countdown wapas start
      } else if (_selectedDateTime!.isBefore(now)) {
        // Agar datetime past me hai
        _isCountdown = false;
      }
    }

    notifyListeners();
  }
}
