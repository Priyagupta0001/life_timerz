import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_timerz/screens/home/home_ui.dart';
import 'package:life_timerz/screens/login/login_ui.dart';
import 'package:life_timerz/services/notification_service.dart';
import 'package:life_timerz/provider/home_provider.dart';
import 'package:life_timerz/provider/forgotpasswordauth_provider.dart';
import 'package:life_timerz/provider/loginauth_provider.dart';
import 'package:life_timerz/provider/noification_provider.dart';
import 'package:life_timerz/provider/profileprovider.dart';
import 'package:life_timerz/provider/task_provider.dart';
import 'package:life_timerz/provider/timer_provider.dart';
import 'package:life_timerz/widgets/app_message.dart';
import 'package:life_timerz/widgets/password_visibility.dart';
import 'package:life_timerz/provider/signupauth_provider.dart';
import 'package:life_timerz/wrapper.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();
  await NotificationService.initialize();

  await Future.delayed(const Duration(seconds: 2));
  FlutterNativeSplash.remove();

    // Sirf portrait modes allow karne ke liye
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SignupAuthProvider()),
            ChangeNotifierProvider(create: (_) => LoginAuthProvider()),
            ChangeNotifierProvider(create: (_) => ForgotPasswordAuthProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => TimerProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => HomeProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => PasswordVisibilityProvider()),
            ChangeNotifierProvider(create: (_) => AppMessageProvider()),
          ],
          child: Builder(
            builder: (context) {
              final showmessage = Provider.of<AppMessageProvider>(
                context,
                listen: false,
              );

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                scaffoldMessengerKey: showmessage.scaffoldMessengerKey,
                initialRoute: '/',
                routes: {
                  '/': (context) => const Wrapper(),
                  '/home': (context) => const HomeUI(),
                  '/login': (context) => const LogInUI(),
                },
              );
            },
          ),
        );
      },
    );
  }
}
