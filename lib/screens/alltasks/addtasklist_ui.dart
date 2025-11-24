// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ Added

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: taskProvider.sortedTasks.length,
              itemBuilder: (_, index) {
                final t = taskProvider.sortedTasks[index];
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

                return Dismissible(
                  key: Key(t.id),

                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20.w),
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
                      if (msg != null) showmessage.showSuccess(msg, context);
                      return false;
                    } else if (direction == DismissDirection.endToStart) {
                      msg = await taskProvider.deleteTask(index);
                      if (msg != null) showmessage.showError(msg, context);
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
                      vertical: 14.h,
                      horizontal: 6.w,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
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
                                  fontSize: 16.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6.h),

                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 18.sp,
                                    color: Colors.black87,
                                  ),
                                  SizedBox(width: 6.w),

                                  CountdownText(
                                    targetTime: datetime,
                                    isCompleted: isCompleted,
                                    taskId: t.id,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: Icon(
                            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            color: isPinned ? Colors.blue : Colors.grey,
                            size: 22.sp,
                          ),
                          onPressed: () async {
                            final msg = await taskProvider.togglePin(t.id);
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
    final done = taskData['isCompleted'] ?? false;
    final now = DateTime.now();
    final diff = targetTime.difference(now);

    if (done || diff.isNegative) return "Completed!";

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
            );
          },
        );
      },
    );
  }
}
