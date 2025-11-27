import 'package:flutter/foundation.dart';
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF6F6F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: SingleChildScrollView(
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
                          fontSize: isLandscape ? 14.sp : 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.black54,
                          size: isLandscape ? 14.sp : 20.sp,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: isLandscape ? 8.h : 10.h),
                  Text(
                    "Title",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontSize: isLandscape ? 10.sp : 14.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isLandscape ? 12.sp : 16.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isLandscape ? 10.h : 16.h),
                  Text(
                    "Time",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontSize: isLandscape ? 10.sp : 14.sp,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _formatRemainingTime(datetime),
                    style: TextStyle(
                      fontSize: isLandscape ? 12.sp : 16.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isLandscape ? 12.h : 24.h),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 100.w : 115.w,
                          vertical: isLandscape ? 8.h : 12.h,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateNewTimerPage(
                              isEditing: true,
                              existingTitle: taskData['title'],
                              existingCategory: taskData['category'],
                              existingDateTime:
                                  (taskData['datetime'] as Timestamp).toDate(),
                              existingIsCountdown:
                                  taskData['isCountDown'] ?? false,
                              docId: taskId,
                              existingIsCompleted:
                                  taskData['isCompleted'] ?? false,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "EDIT",
                        style: TextStyle(
                          fontSize: isLandscape ? 12.sp : 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatRemainingTime(DateTime targetTime) {
    final now = DateTime.now();
    Duration diff = targetTime.difference(now);

    // Clamp negative durations to zero
    if (diff.isNegative) diff = Duration.zero;

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    // If duration is zero, show completed
    if (diff == Duration.zero) return "Completed!";

    return "$days days, $hours hours, $minutes minutes";
  }

  @override
  Widget build(BuildContext context) {
    final home = Provider.of<HomeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final taskProvider = context.watch<TaskProvider>();

    // Detect if device is in landscape mode
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
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
      body: SafeArea(child: _buildBody(context, home, user)),
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
                existingIsCompleted: null,
              ),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 32, 82, 233),
        shape: const CircleBorder(),
        child: Icon(
          Icons.add,
          size: isLandscape ? 24.sp : 30.sp,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: CustomBottomNavBar(
            selectedIndex: home.selectedIndex,
            onItemTapped: (index) => home.onItemTapped(index),
          ),
        ),
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

    // Detect if device is in landscape mode
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: EdgeInsets.all(isLandscape ? 10.w : 18.w),
      child: StreamBuilder<QuerySnapshot>(
        stream: home.getAllTasks(),
        builder: (context, topSnapshot) {
          if (!topSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final all = topSnapshot.data!.docs;
          final pinned = all.where((doc) => doc['isPinned'] == true).toList();

          return ListView(
            children: [
              // -------- TOP COUNTS --------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _countBox(
                      title: "Pin Task",
                      count: pinned.length,
                      color: const Color.fromARGB(255, 226, 188, 223),
                      icon: Icons.push_pin_outlined,
                      iconColor: Colors.red,
                      onTap: () => home.togglePinnedView(true),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _countBox(
                      title: "Total Task",
                      count: all.length,
                      color: const Color.fromARGB(255, 230, 237, 255),
                      icon: Icons.task_alt_outlined,
                      iconColor: Colors.blue,
                      onTap: () => home.togglePinnedView(false),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // ---------- HEADING ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        home.showPinnedOnly ? "Pin Tasks" : "All Tasks",
                        style: TextStyle(
                          fontSize: isLandscape ? 16.sp : 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis, //ladscape
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => home.onItemTapped(1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "view all",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 8, 64, 233),
                              fontSize: isLandscape ? 12.sp : 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        CircleAvatar(
                          radius: isLandscape ? 8.r : 9.r,
                          backgroundColor: const Color.fromARGB(
                            255,
                            8,
                            64,
                            233,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: isLandscape ? 6.sp : 12.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // -------- TASK LIST (scrolls properly) -------
              StreamBuilder<QuerySnapshot>(
                stream: home.showPinnedOnly
                    ? home.getPinnedTasks()
                    : home.getAllTasks(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(20.h),
                      child: Center(
                        child: Text(
                          "No tasks found!",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final task = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;
                      return _taskTile(context, home, id, task);
                    },
                  );
                },
              ),
            ],
          );
        },
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
    final bool isLandscape =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width >
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 10.w : 18.w,
          vertical: isLandscape ? 8.h : 16.h,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ICON BOX
            Container(
              padding: EdgeInsets.all(isLandscape ? 8.w : 15.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isLandscape ? 16.sp : 24.sp,
              ),
            ),

            SizedBox(width: isLandscape ? 8.w : 12.w),

            // COUNT + TITLE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$count",
                    style: TextStyle(
                      fontSize: isLandscape ? 18.sp : 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: isLandscape ? 12.sp : 14.sp),
                  ),
                ],
              ),
            ),
          ],
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

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Dismissible(
      key: Key(id),

      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: isLandscape ? 16.w : 20.w),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(isLandscape ? 10.r : 12.r),
        ),
        child: Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: isLandscape ? 18.sp : 22.sp,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: isLandscape ? 16.w : 20.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(isLandscape ? 10.r : 12.r),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: isLandscape ? 18.sp : 22.sp,
        ),
      ),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await homeProv.markTaskCompleted(id);
          taskProvider.notifyListeners();
          return true;
        } else if (direction == DismissDirection.endToStart) {
          await homeProv.deleteTask(id);
          return true;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => showCustomEditDialog(context, id, task),
        child: Container(
          margin: EdgeInsets.only(bottom: isLandscape ? 10.h : 14.h),
          padding: EdgeInsets.all(isLandscape ? 10.w : 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isLandscape ? 10.r : 12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: isLandscape ? 4.r : 6.r,
                offset: Offset(0, isLandscape ? 1.h : 2.h),
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
                        fontSize: isLandscape ? 12.sp : 16.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: isLandscape ? 4.h : 6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: isLandscape ? 14.sp : 20.sp,
                        ),
                        SizedBox(width: isLandscape ? 3.w : 4.w),
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
                      ? const Color.fromARGB(255, 8, 64, 233)
                      : Colors.grey,
                  size: isLandscape ? 15.sp : 22.sp,
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
    required this.isCompleted,
  });

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return "$days days, $hours hours, $minutes minutes, $seconds seconds";
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final task = taskProvider.getTaskById(taskId);
        if (task == null) return SizedBox();

        final isCompleted = task.data['isCompleted'] ?? false;
        final isCountdown = task.data['isCountDown'] ?? true;
        final duration = taskProvider.getTaskDuration(taskId);

        // Agar task complete hai ya countdown off ya time past → show Completed
        final showCompleted =
            isCompleted || !isCountdown || duration.isNegative;

        final displayText = showCompleted
            ? "Completed!"
            : _formatDuration(duration);

        return Text(
          displayText,
          style: TextStyle(
            color: showCompleted ? Colors.green : Colors.black,
            fontWeight: showCompleted ? FontWeight.bold : FontWeight.normal,
            fontSize: isLandscape ? 10.sp : 12.sp,
          ),
        );
      },
    );
  }
}
