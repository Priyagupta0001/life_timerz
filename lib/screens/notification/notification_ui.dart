import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/noification_provider.dart';
import 'package:provider/provider.dart';

class NotificationUI extends StatelessWidget {
  const NotificationUI({super.key});

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final notifications = provider.notifications;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Landscape me thoda compact, portrait me normal
    final scale = isLandscape ? 0.85 : 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: notifications.isEmpty
          ? Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.grey, fontSize: 16.sp * scale),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w * scale,
                vertical: 8.h * scale,
              ),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final date = DateTime.tryParse(n['time'] ?? '');

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6.h * scale),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w * scale,
                    vertical: 12.h * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 246, 246, 255),
                    borderRadius: BorderRadius.circular(18.r * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha((0.15 * 255).toInt()),
                        blurRadius: 8.r * scale,
                        offset: Offset(0, 4.h * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TITLE
                      Text(
                        n['title'] ?? '',
                        style: TextStyle(
                          fontSize: 15.5.sp * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      /// BODY (optional)
                      if ((n['body'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            left: 3.w * scale,
                            top: 4.h * scale,
                          ),
                          child: Text(
                            n['body'],
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14.sp * scale,
                              height: 1.3,
                            ),
                          ),
                        ),

                      /// TIME ROW
                      Padding(
                        padding: EdgeInsets.only(
                          left: 3.w * scale,
                          top: 5.h * scale,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.sp * scale,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 6.w * scale),
                            Text(
                              date != null
                                  ? _formatTimeAgo(date)
                                  : 'Unknown time',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13.sp * scale,
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
