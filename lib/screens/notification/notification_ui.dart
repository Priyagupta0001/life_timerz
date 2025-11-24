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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.grey, fontSize: 16.sp),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final date = DateTime.tryParse(n['time'] ?? '');

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 246, 246, 255),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withAlpha((0.15 * 255).toInt()),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
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
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      /// BODY (optional)
                      if ((n['body'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(left: 3.w, top: 4.h),
                          child: Text(
                            n['body'],
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14.sp,
                              height: 1.3,
                            ),
                          ),
                        ),

                      /// TIME ROW
                      Padding(
                        padding: EdgeInsets.only(left: 3.w, top: 5.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              date != null
                                  ? _formatTimeAgo(date)
                                  : 'Unknown time',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13.sp,
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
