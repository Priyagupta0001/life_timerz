import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:life_timerz/provider/home_provider.dart';
import 'package:life_timerz/widgets/customappbar.dart';
import 'package:life_timerz/widgets/custombottomnavbar.dart';
import 'package:life_timerz/screens/alltasks/addtasklist_ui.dart';
import 'package:life_timerz/screens/createTimer/createnewtimer_ui.dart';
import 'package:life_timerz/screens/profile/profile_ui.dart';
import 'package:life_timerz/screens/notification/notification_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeUI extends StatelessWidget {
  const HomeUI({super.key});

  // ------------------ Edit Alert Dialog ------------------
  void showCustomEditDialog(
    BuildContext context,
    String taskId,
    Map<String, dynamic> taskData,
  ) {
    final title = taskData['title'] ?? '';
    final datetime = (taskData['datetime'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF6F6F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Task",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 20.sp,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  "Title",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Time",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _formatRemainingTime(datetime),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.h),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 115.w,
                        vertical: 12.h,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateNewTimerPage(
                            isEditing: true,
                            existingTitle: title,
                            existingDateTime: datetime,
                            docId: taskId,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "EDIT",
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRemainingTime(DateTime targetTime) {
    final now = DateTime.now();
    final diff = targetTime.difference(now);
    if (diff.isNegative) return "Completed!";
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    return "$days days, $hours hours, $minutes minutes";
  }

  @override
  Widget build(BuildContext context) {
    final home = Provider.of<HomeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: home.titles[home.selectedIndex],
        selectedIndex: home.selectedIndex,
        selectedSort: taskProvider.selectedSort,
        sortOptions: taskProvider.sortOptions,
        onSortChanged: (newSort) {
          taskProvider.setSort(newSort);
        },
        backgroundColor: const Color.fromARGB(255, 201, 220, 240),
        style: const TextStyle(),
      ),
      body: _buildBody(context, home, user),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNewTimerPage(
                isEditing: false,
                existingTitle: null,
                existingDateTime: null,
                docId: null,
              ),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 32, 82, 233),
        shape: const CircleBorder(),
        child: Icon(Icons.add, size: 30.sp, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: home.selectedIndex,
        onItemTapped: home.onItemTapped,
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeProvider home, User? user) {
    if (home.selectedIndex == 0) {
      return _homeTab(context, home, user);
    } else if (home.selectedIndex == 1) {
      return AddTaskListUI(
        showPinnedOnly: home.showPinnedOnly,
        selectedSort: home.selectedSort,
      );
    } else if (home.selectedIndex == 2) {
      return const ProfileUI();
    } else {
      return const NotificationUI();
    }
  }

  Widget _homeTab(BuildContext context, HomeProvider home, User? user) {
    if (user == null) {
      return Center(
        child: Text("User not logged in!", style: TextStyle(fontSize: 14.sp)),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Top Counts --------
          StreamBuilder<QuerySnapshot>(
            stream: home.getAllTasks(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final all = snapshot.data!.docs;
              final pinned = all
                  .where((doc) => (doc['isPinned'] == true))
                  .toList();

              return Row(
                children: [
                  _countBox(
                    title: "Pin Task",
                    count: pinned.length,
                    color: const Color.fromARGB(255, 226, 188, 223),
                    icon: Icons.push_pin_outlined,
                    iconColor: Colors.red,
                    onTap: () => home.togglePinnedView(true),
                  ),
                  _countBox(
                    title: "Total Task",
                    count: all.length,
                    color: const Color.fromARGB(255, 230, 237, 255),
                    icon: Icons.task_alt_outlined,
                    iconColor: Colors.blue,
                    onTap: () => home.togglePinnedView(false),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 20.h),

          // ---------- Heading ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                home.showPinnedOnly ? "Pin Tasks" : "All Tasks",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => home.onItemTapped(1),
                child: Row(
                  children: [
                    Text(
                      "view all",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 8, 64, 233),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    CircleAvatar(
                      radius: 10.r,
                      backgroundColor: const Color.fromARGB(255, 8, 64, 233),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // Pinned or All tasks list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: home.showPinnedOnly
                  ? home.getPinnedTasks()
                  : home.getAllTasks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No tasks found!",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final task = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    return _taskTile(context, home, id, task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBox({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(18.w),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$count",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title, style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskTile(
    BuildContext context,
    HomeProvider home,
    String id,
    Map<String, dynamic> task,
  ) {
    final homeProv = Provider.of<HomeProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final title = task['title'] ?? "";
    final category = task['category'] ?? "";
    final datetime = (task['datetime'] as Timestamp).toDate();
    final isCompleted = task['isCompleted'] ?? false;
    final isPinned = task['isPinned'] ?? false;

    return Dismissible(
      key: Key(id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 22.sp,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 22.sp),
      ),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await homeProv.markTaskCompleted(id);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          await homeProv.deleteTask(id);
          return true;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => showCustomEditDialog(context, id, task),
        child: Container(
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$category - $title",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20.sp),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: CountdownText(
                            taskId: id,
                            targetTime: datetime,
                            isCompleted: isCompleted,
                          ),
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
                      ? const Color.fromRGBO(33, 150, 243, 1)
                      : Colors.grey,
                  size: 22.sp,
                ),
                onPressed: () async {
                  await taskProvider.togglePin(id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CountdownText extends StatelessWidget {
  final String taskId;
  final DateTime targetTime;
  final bool isCompleted;

  const CountdownText({
    super.key,
    required this.taskId,
    required this.targetTime,
    this.isCompleted = false,
  });

  Stream<int> _ticker() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      yield 1;
    }
  }

  String _getRemaining(Map<String, dynamic> taskData) {
    final isCompleted = taskData['isCompleted'] ?? false;
    final now = DateTime.now();
    final diff = targetTime.difference(now);

    if (isCompleted || diff.isNegative) return "Completed!";

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return "$days days, $hours hours, $minutes minutes, $seconds seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final task = taskProvider.getTaskById(taskId);
        if (task == null) return SizedBox();

        return StreamBuilder<int>(
          stream: _ticker(),
          builder: (context, snapshot) {
            final remaining = _getRemaining(task.data);
            final done = task.data['isCompleted'] ?? false;

            return Text(
              remaining,
              style: TextStyle(
                color: done ? Colors.green : Colors.black,
                fontWeight: done ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.sp,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          },
        );
      },
    );
  }
}
