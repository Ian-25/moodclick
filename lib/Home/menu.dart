import 'package:flutter/material.dart';
import 'package:moodapp/Burgerbuttonfunc/SpeAdvice.dart';
import 'package:moodapp/Burgerbuttonfunc/Appointment.dart';
import 'package:moodapp/Burgerbuttonfunc/appoint.status.dart';
import 'package:moodapp/Burgerbuttonfunc/privacypolicy.dart';
import 'package:moodapp/Burgerbuttonfunc/wellness.dart';
import 'package:moodapp/Home/home.dart';
import 'package:moodapp/Login Signup/login.dart';
import 'package:moodapp/Services/auth_service.dart';

void main() {
  runApp(const MoodClickApp());
}

class MoodClickApp extends StatelessWidget {
  const MoodClickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const BurgerButton(), // Add the drawer to the scaffold
      body: const Center(child: Text('Home Page')),
    );
  }
}

class BurgerButton extends StatefulWidget {
  const BurgerButton({super.key});

  @override
  State<BurgerButton> createState() => _BurgerButtonState();
}

class _BurgerButtonState extends State<BurgerButton> {
  String nickname = '';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  void _loadNickname() async {
    var userDetails = await AuthService().getUserDetails();
    if (mounted) {
      setState(() {
        nickname = userDetails['nickname'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(nickname),
            accountEmail: const Text('Welcome to MoodClick'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 243, 33, 33),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Book Appointment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AppointmentPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions),
            title: const Text('Appointment Status'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AppointmentStatus()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.self_improvement),
            title: const Text('Wellness Corner'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WellnessPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicy()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService().signout(context: context);
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DrawerItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

// Dummy screens for navigation
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: const Center(child: Text('Messages Screen')),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact for Counselling')),
      body: const Center(child: Text('Contact Screen')),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions')),
      body: const Center(child: Text('Terms and Conditions Screen')),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Center(child: Text('Privacy Policy Screen')),
    );
  }
}
