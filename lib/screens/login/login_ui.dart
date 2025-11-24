// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/loginauth_provider.dart';
import 'package:life_timerz/provider/profileprovider.dart';

import 'package:life_timerz/screens/forgotpassword/forgotpassword_ui.dart';
import 'package:life_timerz/screens/signup/signup_ui.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:life_timerz/widgets/password_visibility.dart';
import 'package:provider/provider.dart';

class LogInUI extends StatefulWidget {
  const LogInUI({super.key});

  @override
  State<LogInUI> createState() => _LogInUIState();
}

class _LogInUIState extends State<LogInUI> {
  // Form key must live inside the State of the login screen (prevents duplicate GlobalKey)
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // don't listen here for whole widget rebuilds
    final loginAuthProvider = Provider.of<LoginAuthProvider>(
      context,
      listen: false,
    );
    final appMsg = Provider.of<AppMessageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 246, 246, 255),
        toolbarHeight: 18.h,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOGO
                Container(
                  width: double.infinity,
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 246, 246, 255),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30.r),
                      bottomRight: Radius.circular(30.r),
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/logo_img.png'),
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),

                // Heading
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 30.h,
                    horizontal: 20.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Enter the below details',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),

                // EMAIL + PASSWORD
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 20.w,
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: loginAuthProvider.emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Id',
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(Icons.person_outline, size: 22.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email!';
                          } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return 'Enter a valid email!';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20.h),

                      Consumer<PasswordVisibilityProvider>(
                        builder: (context, visible, child) {
                          return TextFormField(
                            controller: loginAuthProvider.passwordController,
                            obscureText: visible.obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                              ),
                              prefixIcon: Icon(Icons.lock_outline, size: 22.sp),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  visible.obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: visible.togglePassword,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              } else if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Forgot
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ForgotPasswordUI()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                // LOGIN BUTTON (only this part listens to provider loading state)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: Consumer<LoginAuthProvider>(
                      builder: (_, provider, __) {
                        return ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    String res = await loginAuthProvider.logIn(
                                      context,
                                    );
                                    if (res == "success") {
                                      User? loggedInUser =
                                          FirebaseAuth.instance.currentUser;
                                      Provider.of<ProfileProvider>(
                                        context,
                                        listen: false,
                                      ).setUser(loggedInUser!);

                                      // Show success message
                                      appMsg.showSuccess(
                                        "Login successful!",
                                        context,
                                      );

                                      // Navigate to home
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/home',
                                      );
                                    } else {
                                      appMsg.showError(res, context);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              32,
                              82,
                              233,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          child: provider.isLoading
                              ? SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),

                // OR
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 100.w,
                    vertical: 20.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Divider(thickness: 1.h)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text('or', style: TextStyle(fontSize: 14.sp)),
                      ),
                      Expanded(child: Divider(thickness: 1.h)),
                    ],
                  ),
                ),

                // GOOGLE + APPLE
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: 10.w,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          icon: Icon(
                            Icons.apple,
                            color: Colors.black,
                            size: 25.sp,
                          ),
                          label: Text(
                            'Apple',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            String res = await loginAuthProvider.googleLogin(
                              context,
                            );
                            if (res == "success") {
                              Navigator.pushReplacementNamed(context, "/home");
                            } else {
                              appMsg.showError(res, context);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: 10.w,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          icon: Icon(
                            Icons.g_mobiledata,
                            color: Colors.black,
                            size: 35.sp,
                          ),
                          label: Text(
                            'Google',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // SIGNUP
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15.sp,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpUI()),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 32, 82, 233),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
