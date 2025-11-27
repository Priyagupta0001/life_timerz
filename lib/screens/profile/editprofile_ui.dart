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

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 10.w : 20.w,
            vertical: isLandscape ? 10.h : 20.h,
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: isLandscape ? 5.h : 10.h),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 152, 167, 197),
                      blurRadius: isLandscape ? 8.r : 12.r,
                      spreadRadius: isLandscape ? 1.r : 2.r,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                  radius: isLandscape ? 30.r : 40.r,
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: isLandscape ? 12.sp : 40.sp,
                  ),
                ),
              ),
              SizedBox(height: isLandscape ? 10.h : 14.h),
              Text(
                "Your Details Has Successfully Changed!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isLandscape ? 11.sp : 20.sp),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: isLandscape ? 110.w : 140.w,
              height: isLandscape ? 38.h : 40.h,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLandscape ? 8.sp : 14.sp,
                  ),
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

        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 246, 246, 255),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: isLandscape ? 11.sp : 20.sp,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isLandscape ? 11.sp : 18.sp,
              ),
            ),
            centerTitle: true,
          ),

          /// ---------------- BODY ----------------
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: isLandscape ? 18.h : 25.h),
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
                              padding: EdgeInsets.symmetric(
                                vertical: isLandscape ? 9.h : 15.h,
                                horizontal: isLandscape ? 8.w : 15.w,
                              ),
                              child: CircleAvatar(
                                radius: isLandscape ? 50.r : 60.r,
                                backgroundImage: const NetworkImage(
                                  'https://picsum.photos/250',
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: isLandscape ? -1.h : 5.h,
                              child: CircleAvatar(
                                radius: isLandscape ? 15.r : 14.r,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: isLandscape ? 6.sp : 24.sp,
                                  color: const Color.fromARGB(255, 32, 82, 233),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isLandscape ? 20.h : 30.h),

                      /// Name Field
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 14.w : 18.w,
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: isLandscape ? 11.sp : 14.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isLandscape ? 5.r : 6.r,
                              ),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Please enter your name'
                              : null,
                        ),
                      ),

                      SizedBox(height: isLandscape ? 16.h : 18.h),

                      /// Email Field
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 14.w : 18.w,
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: isLandscape ? 11.sp : 14.sp,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// ---------------- SAVE BUTTON ----------------
          bottomNavigationBar: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: isLandscape ? 16.w : 20.w,
                  right: isLandscape ? 16.w : 20.w,
                  bottom: isLandscape ? 28.h : 40.h,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: isLandscape ? 40.h : 46.h,
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
                        borderRadius: BorderRadius.circular(
                          isLandscape ? 5.r : 6.r,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: isLandscape ? 12.w : 20.w,
                            height: isLandscape ? 12.h : 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'SAVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLandscape ? 8.sp : 16.sp,
                            ),
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
