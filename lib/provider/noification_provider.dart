import 'dart:async';
import 'package:flutter/material.dart';
import 'package:life_timerz/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  Timer? _timer;

  List<Map<String, dynamic>> get notifications => _notifications;

  NotificationProvider() {
    _startFetching();
  }

  void _startFetching() {
    _fetchNotifications(); // initial load
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    final fetched = await NotificationService.getAllNotifications();
    _notifications = fetched;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
