// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/task_provider.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:provider/provider.dart';

class AddTaskListUI extends StatelessWidget {
  final dynamic showPinnedOnly;
  final String selectedSort;

  const AddTaskListUI({
    super.key,
    this.showPinnedOnly = false,
    required this.selectedSort,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final showmessage = Provider.of<AppMessageProvider>(context, listen: false);

    if (taskProvider.user == null) {
      return Center(
        child: Text("User not logged in!", style: TextStyle(fontSize: 14.sp)),
      );
    }

    final tasks = taskProvider.sortedTasks;

    return Scaffold(
      backgroundColor: Colors.white,
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No tasks found!",
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, index) {
                      final t = tasks[index];
                      final data = t.data;

                      // Parse datetime
                      final raw = data['datetime'];
                      DateTime datetime;

                      if (raw is Timestamp) {
                        datetime = raw.toDate();
                      } else if (raw is DateTime) {
                        datetime = raw;
                      } else {
                        datetime =
                            DateTime.tryParse(raw.toString()) ?? DateTime.now();
                      }

                      final isPinned = data['isPinned'] ?? false;
                      final isCompleted = data['isCompleted'] ?? false;

                      final isLandscape =
                          MediaQuery.of(context).orientation ==
                          Orientation.landscape;

                      return Dismissible(
                        key: Key(t.id),

                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(
                            left: isLandscape ? 12.w : 20.w,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),

                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.w),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),

                        direction: DismissDirection.horizontal,

                        confirmDismiss: (direction) async {
                          String? msg;
                          if (direction == DismissDirection.startToEnd) {
                            msg = await taskProvider.markCompleted(t.id);
                            if (msg != null) {
                              showmessage.showSuccess(msg, context);
                            }
                            return false;
                          } else if (direction == DismissDirection.endToStart) {
                            msg = await taskProvider.deleteTask(index);
                            if (msg != null) {
                              showmessage.showError(msg, context);
                            }
                            return true;
                          }
                          return false;
                        },

                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 18.h,
                            horizontal: 17.w,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  212,
                                  211,
                                  211,
                                ).withOpacity(0.15),
                                blurRadius: 8.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title - Category
                                    Text(
                                      "${data['category']} - ${data['title']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isLandscape ? 11.sp : 16.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isLandscape ? 4.h : 6.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: isLandscape ? 14.sp : 20.sp,
                                          color: Colors.black87,
                                        ),
                                        SizedBox(
                                          width: isLandscape ? 3.w : 4.w,
                                        ),
                                        Expanded(
                                          child: CountdownText(
                                            targetTime: datetime,
                                            isCompleted: isCompleted,
                                            taskId: t.id,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon: Icon(
                                  isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  color: isPinned
                                      ? const Color.fromARGB(255, 32, 82, 233)
                                      : Colors.grey,
                                  size: isLandscape ? 15.sp : 22.sp,
                                ),
                                onPressed: () async {
                                  final msg = await taskProvider.togglePin(
                                    t.id,
                                  );
                                  if (msg != null) {
                                    final pinnedNow = !isPinned;
                                    pinnedNow
                                        ? showmessage.showSuccess(msg, context)
                                        : showmessage.showError(msg, context);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class CountdownText extends StatelessWidget {
  final String taskId;

  const CountdownText({
    super.key,
    required this.taskId,
    required targetTime,
    required isCompleted,
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
        final duration = taskProvider.getTaskDuration(taskId);

        return Text(
          isCompleted ? "Completed!" : _formatDuration(duration),
          style: TextStyle(
            color: isCompleted ? Colors.green : Colors.black,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            fontSize: isLandscape ? 10.sp : 12.sp,
          ),
        );
      },
    );
  }
}
