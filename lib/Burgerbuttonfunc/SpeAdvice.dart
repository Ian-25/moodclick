import 'package:flutter/material.dart';

class SpeAdvice extends StatelessWidget {
  final String moodIssue;

  const SpeAdvice({super.key, required this.moodIssue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expert Advice on $moodIssue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expert Advice Forum',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Here you can find advice from experts on how to deal with $moodIssue.',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildAdviceCard(
                    'Dr. John Doe',
                    'Psychologist',
                    'It is important to acknowledge your feelings and talk to someone you trust about what you are going through.',
                  ),
                  _buildAdviceCard(
                    'Dr. Jane Smith',
                    'Therapist',
                    'Practicing mindfulness and meditation can help you manage your $moodIssue more effectively.',
                  ),
                  _buildAdviceCard(
                    'Dr. Emily Johnson',
                    'Counselor',
                    'Engaging in physical activities and maintaining a healthy lifestyle can improve your mental well-being.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceCard(String name, String title, String advice) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              advice,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
