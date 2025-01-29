import 'package:flutter/material.dart';
import 'package:moodapp/Burgerbuttonfunc/SpeAdvice.dart';
import 'package:moodapp/Burgerbuttonfunc/councelling.dart';
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
  _BurgerButtonState createState() => _BurgerButtonState();
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
    setState(() {
      nickname = userDetails['nickname'] ?? '';
    });
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
              color: Colors.blue,
            ),
          ),
          const Divider(),
          DrawerItem(
            title: 'Home',
            icon: Icons.home,
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()));
            },
          ),
          DrawerItem(
            title: 'Counsellors Advice',
            icon: Icons.message,
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const SpeAdvice(moodIssue: 'The Counsellors')));
            },
          ),
          DrawerItem(
            title: 'Contact for Counselling',
            icon: Icons.contact_phone,
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>CounsellorsProfilePage()));
            },
          ),
          DrawerItem(
            title: 'Terms and Conditions',
            icon: Icons.description,
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()));
            },
          ),
          DrawerItem(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip,
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen()));
            },
          ),
          const Divider(),
          DrawerItem(
            title: 'Logout',
            icon: Icons.logout,
            onTap: () async {
              await AuthService().signout(context: context);
              Navigator.pop(context); // Close the drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
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

  const DrawerItem({super.key, 
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
