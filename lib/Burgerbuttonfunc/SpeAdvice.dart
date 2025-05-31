import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpeAdvice extends StatefulWidget {
  final String moodIssue;

  const SpeAdvice({super.key, required this.moodIssue});

  @override
  State<SpeAdvice> createState() => _SpeAdviceState();
}

class _SpeAdviceState extends State<SpeAdvice> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expert Advice on ${widget.moodIssue}'),
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
              'Here you can find advice from experts on how to deal with ${widget.moodIssue}.',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('guidance_account').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No counselors available at the moment'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var counselorData = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      return _buildAdviceCard(
                        counselorData['displayName'] ?? 'Anonymous Counselor',
                        counselorData['title'] ?? 'Counselor',
                        counselorData['advice'] ??
                            'Breaks Are Not a Crime Staring at your notes for five hours straight doesnt mean youre studying—it just means youre torturing yourself. Take breaks. Stand up. Touch some grass. Look at a tree. The assignment will still be there when you get back, unfortunately.',
                      );
                    },
                  );
                },
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
