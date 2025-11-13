import 'dart:async';
import 'package:flutter/material.dart';
import 'package:life_timerz/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  Timer? _timer;

    @override
  void initState() {
    super.initState();
    _loadNotifications();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadNotifications());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final notifs = await NotificationService.getAllNotifications();
    setState(() {
      notifications = notifs;
    });
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final date = DateTime.tryParse(n['time'] ?? '');
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 246, 246, 255),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((n['body'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 3, top: 4),
                          child: Text(
                            n['body'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 3, top: 5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              date != null
                                  ? _formatTimeAgo(date)
                                  : 'Unknown time',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
