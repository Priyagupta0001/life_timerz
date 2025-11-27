import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:life_timerz/widgets/password_visibility.dart';
import 'package:provider/provider.dart';
import 'package:life_timerz/provider/signupauth_provider.dart';

class SignUpUI extends StatefulWidget {
  const SignUpUI({super.key});

  @override
  State<SignUpUI> createState() => _SignUpUIState();
}

class _SignUpUIState extends State<SignUpUI> {
  @override
  Widget build(BuildContext context) {
    final signupAuthProvider = Provider.of<SignupAuthProvider>(context);
    final showmessage = Provider.of<AppMessageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 246, 246, 255),
        toolbarHeight: 12.h,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: signupAuthProvider.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Section
                Container(
                  height: 140.h,
                  width: double.infinity,
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

                // Title Text
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 30.h,
                    horizontal: 20.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Create your account below',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: signupAuthProvider.nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Please enter your name" : null,
                      ),
                      SizedBox(height: 10.h),

                      // Email
                      TextFormField(
                        controller: signupAuthProvider.emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Id',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return "Please enter email!";
                          if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return "Enter valid email!";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10.h),

                      // Password
                      Consumer<PasswordVisibilityProvider>(
                        builder: (context, visible, child) {
                          return TextFormField(
                            controller: signupAuthProvider.passwordController,
                            obscureText: visible.obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
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
                              if (value!.isEmpty) {
                                return "Please enter password";
                              }
                              if (value.length < 6) {
                                return "Password must be 6+ characters";
                              }
                              return null;
                            },
                          );
                        },
                      ),

                      SizedBox(height: 10.h),

                      // Confirm Password
                      Consumer<PasswordVisibilityProvider>(
                        builder: (context, visible, child) {
                          return TextFormField(
                            controller:
                                signupAuthProvider.confirmPasswordController,
                            obscureText: visible.obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  visible.obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: visible.toggleConfirmPassword,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please confirm password";
                              }
                              if (value !=
                                  signupAuthProvider.passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // SIGN UP button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: signupAuthProvider.isLoading
                          ? null
                          : () async {
                              if (signupAuthProvider.formKey.currentState!
                                  .validate()) {
                                String res = await signupAuthProvider.signUp(
                                  context,
                                );
                                if (res == "success") {
                                  showmessage.showSuccess(
                                    "Account created successfully!",
                                    context,
                                  );
                                } else {
                                  showmessage.showError(res, context);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 32, 82, 233),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      child: signupAuthProvider.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              "SIGN UP",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                            ),
                    ),
                  ),
                ),

                // Divider
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 100.w,
                    vertical: 6.h,
                  ),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text("or", style: TextStyle(fontSize: 14.sp)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),

                // Already have an account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 32, 82, 233),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
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