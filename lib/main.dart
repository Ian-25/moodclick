import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:moodapp/Burgerbuttonfunc/SpeAdvice.dart';

import 'package:moodapp/Burgerbuttonfunc/privacypolicy.dart';
import 'package:moodapp/Burgerbuttonfunc/wellness.dart';
import 'package:moodapp/Home/home.dart';
import 'package:moodapp/Home/menu.dart';
import 'package:moodapp/Login%20Signup/login.dart';
import 'package:moodapp/Login%20Signup/signup.dart';
import 'package:moodapp/MoodUpdate/moodupdate.dart';
import 'package:moodapp/splashscreen.dart';
import 'firebase_options.dart';
import 'package:moodapp/Home/profile.dart';
import 'package:moodapp/Home/notifi.dart';
import 'package:moodapp/Login%20Signup/forgotpass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute:
          '/', // The initial route will be SplashScreen or any other screen you set as '/'
      routes: {
        // Define routes here for navigation between screens
        '/': (context) => const SplashScreen(), // SplashScreen route
        '/moodupdate': (context) =>
            const MoodSelectorScreen(), // Mood Update Screen
        '/login': (context) => const LoginScreen(), // Login screen route
        '/signup': (context) => RegisterScreen(), // Register screen route
        '/home': (context) => const HomeScreen(), // Main Home Screen
        '/menu': (context) => (const BurgerButton()), // Burger Button Screen
        '/notifi': (context) => const NotificationPage(), // Notification Screen
        '/profile': (context) => const ProfilePage(), // Profile Screen
        '/wellness': (context) => const WellnessPage(), // Counselling Screen
        '/SpeAdvice': (context) => const SpeAdvice(
              moodIssue: '',
            ), // advice screen
        '/forgotpass': (context) => const Forgotpass(), // ForgotPassword Screen
        'messages': (context) => const MessagesScreen(),
        'privacypolicy': (context) =>
            const PrivacyPolicyScreen(), // Privacy Policy Screenontext) => const PrivacyPolicy(),
      },
    );
  }
}
