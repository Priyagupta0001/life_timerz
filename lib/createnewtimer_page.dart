import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateNewTimerPage extends StatefulWidget {
  final bool isEditing;
  final String? docId;
  final String? existingTitle;
  final DateTime? existingDateTime;
  final String? existingCategory;

  const CreateNewTimerPage({
    super.key,
    this.isEditing = false,
    this.docId,
    this.existingTitle,
    this.existingDateTime,
    this.existingCategory,
  });

  @override
  State<StatefulWidget> createState() => _CreateNewTimePageState();
}

class _CreateNewTimePageState extends State<CreateNewTimerPage> {
  final TextEditingController _titleController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  bool isCountdown = false;

  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _titleController.text = widget.existingTitle ?? '';
      _selectedCategory = widget.existingCategory;
      selectedDateTime = widget.existingDateTime ?? DateTime.now();
    }
  }

  //select date time
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedDateTime != null
            ? TimeOfDay.fromDateTime(selectedDateTime!)
            : TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // save task to firestore
  Future<void> _saveTimerToFirestore() async {
    if (_titleController.text.isEmpty || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Please enter all details',
            style: TextStyle(color: Colors.red),
          ),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && !widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Please sign in to create a timer',
            style: TextStyle(color: Colors.red),
          ),
          backgroundColor: Colors.black,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (widget.isEditing && widget.docId != null) {
        //UPDATE EXISTING TASK
        await FirebaseFirestore.instance
            .collection('timers')
            .doc(widget.docId)
            .update({
              'title': _titleController.text.trim(),
              'category': _selectedCategory ?? 'Personal',
              'datetime': Timestamp.fromDate(selectedDateTime!),
              'isCountDown': isCountdown,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Task updated successfully!',
              style: TextStyle(color: Colors.green),
            ),
            backgroundColor: Colors.black,
          ),
        );
      } else {
        //CREATE NEW TASK
        await FirebaseFirestore.instance.collection('timers').add({
          'uid': user!.uid,
          'title': _titleController.text.trim(),
          'category': _selectedCategory ?? 'Personal',
          'datetime': Timestamp.fromDate(selectedDateTime!),
          'createdAt': FieldValue.serverTimestamp(),
          'isCountDown': isCountdown,
          'isPinned': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'New task created!',
              style: TextStyle(color: Colors.green),
            ),
            backgroundColor: Colors.black,
          ),
        );
      }

      Navigator.pop(context); // go back after saving
    } catch (e) {
      print("Error saving timer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Error: Failed to save timer',
            style: const TextStyle(color: Colors.red),
          ),
          backgroundColor: Colors.black,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDateTime = selectedDateTime == null
        ? ''
        : DateFormat('MMM d, yyyy hh:mm a').format(selectedDateTime!);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 246, 246, 255),
        //automaticallyImplyLeading: true, //backbutton
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Timer",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedCategory,
              items:
                  [
                        'Work',
                        'Study',
                        'Fitness',
                        'Shopping',
                        'Sleep',
                        'Personal',
                        'Fun',
                        ''
                      ]
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                   _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectDateTime(context),
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    "Select date & time",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (selectedDateTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: Text(
                      formattedDateTime,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(146, 236, 224, 224),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Is this a countdown timer?',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  Switch(
                    value: isCountdown,
                    onChanged: (bool value) {
                      setState(() {
                        isCountdown = value;
                      });
                    },
                    activeColor: const Color.fromARGB(255, 32, 82, 233),
                    activeTrackColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
          child: Row(
            children: [
              // CANCEL Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(146, 236, 224, 224),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // CONFIRM Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTimerToFirestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'CONFIRM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
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
