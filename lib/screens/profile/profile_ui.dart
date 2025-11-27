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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isLandscape ? 15.r : 20.r),
        ),

        contentPadding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 10.w : 20.w,
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 90.w : 30.w,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: isLandscape ? 6.h : 10.h),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 152, 167, 197),
                    blurRadius: isLandscape ? 8.r : 12.r,
                    spreadRadius: isLandscape ? 1.5.r : 2.r,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                radius: isLandscape ? 30.r : 40.r,
                child: Icon(
                  Icons.logout_outlined,
                  color: Colors.white,
                  size: isLandscape ? 14.sp : 40.sp,
                ),
              ),
            ),
            SizedBox(height: isLandscape ? 10.h : 14.h),
            Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: isLandscape ? 16.sp : 20.sp,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure want to logout?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isLandscape ? 10.sp : 14.sp,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CANCEL BUTTON
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isLandscape ? 4.h : 6.h,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isLandscape ? 9.sp : 14.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: isLandscape ? 10.w : 14.w),

                // CONFIRM BUTTON
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isLandscape ? 4.r : 6.r,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isLandscape ? 4.h : 6.h,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await provider.logout();
                  
                      final loginProvider = Provider.of<LoginAuthProvider>(
                        context,
                        listen: false,
                      );
                      loginProvider.clearFields();
                  
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final showMsg = Provider.of<AppMessageProvider>(
                          context,
                          listen: false,
                        );
                        showMsg.showSuccess("Logout successful!", context);
                  
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LogInUI()),
                          (route) => false,
                        );
                      });
                    },
                    child: Text(
                      'CONFIRM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLandscape ? 9.sp : 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
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

        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: isLandscape ? 10.h : 25.h),
              child: SingleChildScrollView(
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
                            padding: EdgeInsets.symmetric(
                              vertical: isLandscape ? 6.h : 15.h,
                              horizontal: isLandscape ? 8.w : 15.w,
                            ),
                            child: CircleAvatar(
                              radius: isLandscape ? 45.r : 60.r,
                              backgroundImage: const NetworkImage(
                                'https://picsum.photos/250',
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: isLandscape ? -4.h : 5.h,
                            child: CircleAvatar(
                              radius: isLandscape ? 12.r : 14.r,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                size: isLandscape ? 7.sp : 24.sp,
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
                        fontSize: isLandscape ? 13.sp : 17.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    // EMAIL
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: isLandscape ? 12.sp : 15.sp,
                        color: Colors.grey[600],
                      ),
                    ),

                    SizedBox(height: isLandscape ? 4.h : 5.h),

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
                        size: isLandscape ? 14.sp : 22.sp,
                      ),
                      label: Text(
                        'EDIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLandscape ? 11.sp : 14.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 16.w : 20.w,
                          vertical: isLandscape ? 4.h : 5.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isLandscape ? 6.r : 8.r,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // OPTIONS LIST
                    ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 4.w : 8.w,
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isLandscape ? 15.h : 15.h,
                            horizontal: isLandscape ? 12.h : 15.h,
                          ),
                          child: Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: isLandscape ? 18.sp : 25.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Divider(height: 1.h, color: Colors.grey[300]),

                        // CHANGE PASSWORD
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLandscape ? 12.h : 15.h,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            horizontalTitleGap: isLandscape ? 8.w : 13.w,
                            dense: true,
                            leading: Icon(
                              Icons.lock_outline,
                              color: provider.isChangePasswordPressed
                                  ? Colors.red
                                  : Colors.black,
                              size: isLandscape ? 15.sp : 22.sp,
                            ),
                            title: Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: isLandscape ? 11.sp : 14.sp,
                                color: provider.isChangePasswordPressed
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: isLandscape ? 12.sp : 16.sp,
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
                        ),

                        Divider(height: 1.h, color: Colors.grey[300]),

                        // LOGOUT
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLandscape ? 11.h : 15.h,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            horizontalTitleGap: isLandscape ? 8.w : 13.w,
                            dense: true,
                            leading: Icon(
                              Icons.logout_outlined,
                              size: isLandscape ? 15.sp : 22.sp,
                              color: provider.isLogoutPressed
                                  ? Colors.red
                                  : Colors.black,
                            ),
                            title: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: isLandscape ? 11.sp : 14.sp,
                                color: provider.isLogoutPressed
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: isLandscape ? 12.sp : 16.sp,
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
