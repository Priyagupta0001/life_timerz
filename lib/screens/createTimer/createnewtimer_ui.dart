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

  const CreateNewTimerPage({
    super.key,
    this.isEditing = false,
    this.docId,
    this.existingTitle,
    this.existingCategory,
    this.existingDateTime,
    this.existingIsCountdown,
  });

  @override
  State<CreateNewTimerPage> createState() => _CreateNewTimerPageState();
}

class _CreateNewTimerPageState extends State<CreateNewTimerPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TimerProvider>(context, listen: false);

      if (widget.isEditing) {
        provider.initialize(
          title: widget.existingTitle,
          category: widget.existingCategory,
          dateTime: widget.existingDateTime,
          isCountdown: widget.existingIsCountdown,
        );
      } else {
        provider.reset(); // blank form for create
      }
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

    switch (result) {
      case "title-empty":
        showmessage.showError("Please enter title", context);
        break;
      case "date-empty":
        showmessage.showError("Please select date & time", context);
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

    // if (widget.isEditing && provider.title.isEmpty) {
    //   provider.setTitle(widget.existingTitle ?? '');
    //   if (widget.existingDateTime != null) {
    //     provider.setDateTime(widget.existingDateTime!);
    //   }
    // }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 222, 222, 230),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? "Edit Timer" : "New Timer",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            TextFormField(
              onChanged: provider.setTitle,
              initialValue: provider.title,
              style: TextStyle(fontSize: 16.sp),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.black, fontSize: 14.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
            ),
            SizedBox(height: 15.h),

            /// CATEGORY DROPDOWN
            DropdownButtonFormField<String>(
              style: TextStyle(fontSize: 15.sp, color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(fontSize: 14.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              value: provider.category.isNotEmpty ? provider.category : null,
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
                              fontSize: 15.sp,
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
                    size: 18.sp,
                  ),
                  label: Text(
                    "Select date & time",
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                    padding: EdgeInsets.symmetric(
                      horizontal: 25.w,
                      vertical: 14.h,
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
                    style: TextStyle(fontSize: 12.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            /// COUNTDOWN SWITCH BOX
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color.fromARGB(146, 236, 224, 224),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Is this a countdown timer?',
                    style: TextStyle(color: Colors.black87, fontSize: 16.sp),
                  ),
                  Switch(
                    value: provider.isCountdown,
                    onChanged: provider.setCountdown,
                    activeThumbColor: const Color.fromARGB(255, 32, 82, 233),
                    activeTrackColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM BUTTONS
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 40.h),
          child: Row(
            children: [
              /// CANCEL
              Expanded(
                child: SizedBox(
                  height: 46.h,
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
                      style: TextStyle(color: Colors.black87, fontSize: 16.sp),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              /// CONFIRM
              Expanded(
                child: SizedBox(
                  height: 46.h,
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
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.w,
                            ),
                          )
                        : Text(
                            'CONFIRM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
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
