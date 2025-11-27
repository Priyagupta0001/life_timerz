// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/timer_provider.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:provider/provider.dart';

class CreateNewTimerPage extends StatefulWidget {
  final bool isEditing;
  final String? docId;
  final String? existingTitle;
  final String? existingCategory;
  final DateTime? existingDateTime;
  final bool? existingIsCountdown;
  final bool? existingIsCompleted;

  const CreateNewTimerPage({
    super.key,
    this.isEditing = false,
    this.docId,
    this.existingTitle,
    this.existingCategory,
    this.existingDateTime,
    this.existingIsCountdown,
    required this.existingIsCompleted,
  });

  @override
  State<CreateNewTimerPage> createState() => _CreateNewTimerPageState();
}

class _CreateNewTimerPageState extends State<CreateNewTimerPage> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TimerProvider>(context, listen: false);

    if (widget.isEditing) {
      provider.initialize(
        title: widget.existingTitle,
        category: widget.existingCategory,
        dateTime: widget.existingDateTime,
        isCountdown: widget.existingIsCountdown,
        isCompleted: widget.existingIsCompleted,
      );
    } else {
      provider.reset();
    }

    _titleController = TextEditingController(text: provider.title);
    _titleController.addListener(() {
      provider.setTitle(_titleController.text);
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final provider = context.read<TimerProvider>();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: provider.selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: provider.selectedDateTime != null
            ? TimeOfDay.fromDateTime(provider.selectedDateTime!)
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        provider.setDateTime(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
      }
    }
  }

  Future<void> _onConfirm(BuildContext context) async {
    final provider = context.read<TimerProvider>();
    final showmessage = Provider.of<AppMessageProvider>(context, listen: false);

    final result = await provider.saveOrUpdateTimer(docId: widget.docId);
    print("Save result: $result"); // Debug

    if (!mounted) return;

    switch (result) {
      case "title-empty":
        showmessage.showError("Please enter title", context);
        break;
      case "date-empty":
        showmessage.showError("Please select date & time", context);
        break;
      case "category-empty":
        showmessage.showError("Please select category", context);
        break;
      case "no-user":
        showmessage.showError("Please login to create timer", context);
        break;
      case "created":
        showmessage.showSuccess("AddTimer created successfully", context);
        provider.reset();
        Navigator.pop(context);
        break;
      case "updated":
        showmessage.showSuccess("UpdateTimer updated successfully", context);
        provider.reset();
        Navigator.pop(context);
        break;
      default:
        showmessage.showError("Error saving timer", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 222, 222, 230),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: isLandscape ? 8.sp : 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? "Edit Timer" : "New Timer",
          style: TextStyle(
            color: Colors.black,
            fontSize: isLandscape ? 11.sp : 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        toolbarHeight: isLandscape ? 45.h : 60.h,
        leadingWidth: isLandscape ? 35.w : 50.w,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: isLandscape ? 20.h : 40.h,
              horizontal: 20.w,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    TextFormField(
                      controller: _titleController,
                      onChanged: provider.setTitle,
                      style: TextStyle(fontSize: isLandscape ? 12.sp : 16.sp),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(
                          color: Colors.black,
                          fontSize: isLandscape ? 11.sp : 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: isLandscape ? 8.h : 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 10.h : 15.h),

                    /// CATEGORY DROPDOWN
                    DropdownButtonFormField<String>(
                      style: TextStyle(
                        fontSize: isLandscape ? 12.sp : 15.sp,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(
                          fontSize: isLandscape ? 11.sp : 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: isLandscape ? 6.h : 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      value: provider.category.isNotEmpty
                          ? provider.category
                          : null,
                      items:
                          [
                                'Work',
                                'Study',
                                'Fitness',
                                'Shopping',
                                'Sleep',
                                'Personal',
                                'Fun',
                                'Art',
                                'Business Work',
                              ]
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: isLandscape ? 12.sp : 15.sp,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) provider.setCategory(val);
                      },
                    ),

                    SizedBox(height: 20.h),

                    /// DATE TIME PICKER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _selectDateTime(context),
                          icon: Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white,
                            size: isLandscape ? 12.sp : 18.sp,
                          ),
                          label: Text(
                            "Select date & time",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLandscape ? 10.sp : 14.sp,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              32,
                              82,
                              233,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isLandscape ? 12.w : 25.w,
                              vertical: isLandscape ? 8.h : 14.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 140.w,
                          child: Text(
                            provider.selectedDateTime != null
                                ? DateFormat(
                                    'MMM d, yyyy hh:mm a',
                                  ).format(provider.selectedDateTime!)
                                : "No date selected",
                            style: TextStyle(
                              fontSize: isLandscape ? 9.sp : 12.sp,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    /// COUNTDOWN SWITCH BOX
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 10.w : 16.w,
                        vertical: isLandscape ? 6.h : 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(146, 236, 224, 224),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Is this a countdown timer?',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: isLandscape ? 12.sp : 16.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Transform.scale(
                            scale: isLandscape ? 0.8 : 1.0,
                            child: Switch(
                              value: provider.isCountdown,
                              onChanged: provider.setCountdown,
                              activeThumbColor: const Color.fromARGB(
                                255,
                                32,
                                82,
                                233,
                              ),
                              activeTrackColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(), // ensures bottom buttons are pushed down
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: isLandscape ? 15.w : 20.w,
            right: isLandscape ? 22.w : 20.w,
            bottom: isLandscape ? 20.h : 40.h,
          ),
          child: Row(
            children: [
              /// CANCEL
              Expanded(
                child: SizedBox(
                  height: isLandscape ? 40.h : 46.h,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(146, 236, 224, 224),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: isLandscape ? 12.sp : 16.sp,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: isLandscape ? 8.w : 12.w),

              /// CONFIRM
              Expanded(
                child: SizedBox(
                  height: isLandscape ? 40.h : 46.h,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => _onConfirm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: provider.isLoading
                        ? SizedBox(
                            width: isLandscape ? 16.w : 20.w,
                            height: isLandscape ? 16.w : 20.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.w,
                            ),
                          )
                        : Text(
                            'CONFIRM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLandscape ? 12.sp : 16.sp,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
