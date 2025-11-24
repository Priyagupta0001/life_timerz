import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/loginauth_provider.dart';
import 'package:life_timerz/provider/profileprovider.dart';
import 'package:life_timerz/screens/login/login_ui.dart';
import 'package:life_timerz/screens/profile/editprofile_ui.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:provider/provider.dart';

class ProfileUI extends StatelessWidget {
  const ProfileUI({super.key});

  // LOGOUT DIALOG
  void _showLogoutDialog(BuildContext context, ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                  Icons.logout_outlined,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20.sp,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure want to logout?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.black, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 32, 82, 233),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context); // pehle dialog close karo

              await provider.logout();

              final loginProvider = Provider.of<LoginAuthProvider>(
                context,
                listen: false,
              );
              loginProvider.clearFields();

              // Show logout message after frame builds
              Future.microtask(() {
                final showMsg = Provider.of<AppMessageProvider>(
                  context,
                  listen: false,
                );
                showMsg.showSuccess("Logout successful!", context);

                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LogInUI()),
                  (route) => false,
                );
              });
            },
            child: Text(
              'CONFIRM',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showmessage = Provider.of<AppMessageProvider>(context, listen: false);

    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final name = provider.userData?['name'] ?? "No Name Available";
        final email = provider.user?.email ?? "No Email Available";

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              child: Column(
                children: [
                  // PROFILE PICTURE
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

                  // NAME
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  // EMAIL
                  Text(
                    email,
                    style: TextStyle(fontSize: 15.sp, color: Colors.grey[600]),
                  ),

                  SizedBox(height: 5.h),

                  // EDIT BUTTON
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileUI(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                    label: Text(
                      'EDIT',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 5.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // OPTIONS LIST
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          child: Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 25.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Divider(height: 1.h, color: Colors.grey[300]),

                        // CHANGE PASSWORD
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          horizontalTitleGap: 13.w,
                          dense: true,
                          leading: Icon(
                            Icons.lock_outline,
                            color: provider.isChangePasswordPressed
                                ? Colors.red
                                : Colors.black,
                            size: 22.sp,
                          ),
                          title: Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: provider.isChangePasswordPressed
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: provider.isChangePasswordPressed
                                ? Colors.red
                                : Colors.black,
                          ),
                          onTap: () async {
                            provider.setChangePasswordPressed(true);
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );

                            provider.setChangePasswordPressed(false);

                            String res = await provider.sendPasswordReset();

                            if (res == "success") {
                              showmessage.showSuccess(
                                'Password reset email sent successfully!',
                                context,
                              );
                            } else {
                              showmessage.showError(res, context);
                            }
                          },
                        ),

                        Divider(height: 1.h, color: Colors.grey[300]),

                        // LOGOUT
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          horizontalTitleGap: 13.w,
                          dense: true,
                          leading: Icon(
                            Icons.logout_outlined,
                            size: 22.sp,
                            color: provider.isLogoutPressed
                                ? Colors.red
                                : Colors.black,
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: provider.isLogoutPressed
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: provider.isLogoutPressed
                                ? Colors.red
                                : Colors.black,
                          ),
                          onTap: () {
                            provider.setLogoutPressed(true);
                            Future.delayed(
                              const Duration(milliseconds: 150),
                              () {
                                _showLogoutDialog(context, provider);
                                provider.setLogoutPressed(false);
                              },
                            );
                          },
                        ),
                      ],
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
}
