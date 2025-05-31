import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color.fromARGB(255, 243, 33, 33),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '1. Introduction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Welcome to our mobile application. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about our policy, or our practices with regards to your personal information, please contact us.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Information We Collect',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We collect personal information that you voluntarily provide to us when registering at the app, expressing an interest in obtaining information about us or our products and services, when participating in activities on the app, or otherwise contacting us.',
            ),
            SizedBox(height: 16),
            Text(
              '3. How We Use Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We use personal information collected via our app for a variety of business purposes described below. We process your personal information for these purposes in reliance on our legitimate business interests, in order to enter into or perform a contract with you, with your consent, and/or for compliance with our legal obligations.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Sharing Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We only share information with your consent, to comply with laws, to provide you with services, to protect your rights, or to fulfill business obligations.',
            ),
            SizedBox(height: 16),
            Text(
              '5. Security of Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.',
            ),
            SizedBox(height: 16),
            Text(
              '6. Your Privacy Rights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'In the Zppu campus, you have rights that allow you greater access to and control over your personal information. You may review, change, or terminate your account at any time.',
            ),
            SizedBox(height: 16),
            Text(
              '7. Changes to This Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We may update this privacy policy from time to time in order to reflect, for example, changes to our practices or for other operational, legal, or regulatory reasons.',
            ),
            SizedBox(height: 16),
            Text(
              '8. Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'If you have questions or comments about this policy, you may contact us by email at: support@moodapp.com',
            ),
          ],
        ),
      ),
    );
  }
}
