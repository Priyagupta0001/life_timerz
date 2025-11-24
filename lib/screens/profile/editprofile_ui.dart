import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/profileprovider.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:provider/provider.dart';

class EditProfileUI extends StatefulWidget {
  const EditProfileUI({super.key});

  @override
  State<EditProfileUI> createState() => _EditProfileUIState();
}

class _EditProfileUIState extends State<EditProfileUI> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    _nameController.text = profileProvider.userData?['name'] ?? '';
    _emailController.text = profileProvider.userData?['email'] ?? '';
  }

  void _showUpdatedDialog(BuildContext context) {
    final updatedName = _nameController.text.trim();
    final updatedEmail = _emailController.text.trim();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 152, 167, 197),
                      blurRadius: 12.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                  radius: 40.r,
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                "Your Details Has Successfully Changed!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.sp),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 140.w,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, {
                    'name': updatedName,
                    'email': updatedEmail,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        final profileProvider = Provider.of<ProfileProvider>(context);
        final showmessage = Provider.of<AppMessageProvider>(
          context,
          listen: false,
        );
        final bool isLoading = profileProvider.isUpdatingProfile;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 246, 246, 255),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20.sp,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            centerTitle: true,
          ),

          /// ---------------- BODY ----------------
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  /// Profile Picture
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(15.w),
                          child: CircleAvatar(
                            radius: 60.r,
                            backgroundImage: const NetworkImage(
                              'https://picsum.photos/250',
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 5.h,
                          child: CircleAvatar(
                            radius: 15.r,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              size: 20.sp,
                              color: const Color.fromARGB(255, 32, 82, 233),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  /// Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your name'
                        : null,
                  ),

                  SizedBox(height: 15.h),

                  /// Email Field
                  TextFormField(
                    controller: _emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ---------------- SAVE BUTTON ----------------
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 40.h),
              child: SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await profileProvider.updateProfile(
                                name: _nameController.text.trim(),
                              );

                              if (mounted) _showUpdatedDialog(context);
                            } catch (e) {
                              showmessage.showError(
                                "Failed to update profile: $e",
                                context,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
