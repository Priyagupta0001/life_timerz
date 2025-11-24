import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/provider/forgotpasswordauth_provider.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:provider/provider.dart';

class ForgotPasswordUI extends StatefulWidget {
  const ForgotPasswordUI({super.key});

  @override
  State<ForgotPasswordUI> createState() => _ForgotPasswordUIState();
}

class _ForgotPasswordUIState extends State<ForgotPasswordUI> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final forgotPasswordProvider = Provider.of<ForgotPasswordAuthProvider>(
      context,
    );

    final showmessage = Provider.of<AppMessageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 246, 246, 255),
        toolbarHeight: 12.h,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Logo Container
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

                  // Back Arrow
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, size: 20.sp),
                        color: Colors.black,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),

                //Heading Text
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 30.h,
                    horizontal: 20.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Enter your registered email below to receive OTP',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color.fromARGB(255, 49, 49, 49),
                        ),
                      ),
                    ],
                  ),
                ),

                //Email TextField + Button
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 20.w,
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: forgotPasswordProvider.email,
                        decoration: InputDecoration(
                          labelText: 'Email Id',
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 15.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.black,
                            size: 22.sp,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        onChanged: (value) {
                          forgotPasswordProvider.email = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email!';
                          } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                            return 'Enter a valid email!';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 19.h),

                      //SEND LINK Button
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                String res = await forgotPasswordProvider
                                    .sendPasswordResetEmail(
                                      context,
                                      email: forgotPasswordProvider.email,
                                    );

                                if (res == "success") {
                                  showmessage.showSuccess(
                                    "Password reset link sent to your email.",
                                    context,
                                  );
                                } else {
                                  showmessage.showError(res, context);
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
                            child: Text(
                              'SEND LINK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
