import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('moodupdate')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No mood updates yet'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              String moodEmoji =
                  data['moodEmoji'] ?? getMoodEmoji(data['mood']);
              String note = data['note'] ?? '';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child:
                        Text(moodEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                  title: Row(
                    children: [
                      Text(
                        data['mood'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDateTime(date),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (note.isNotEmpty)
                        Text(
                          note,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String formatDateTime(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case "happy":
        return "😊";
      case "sad":
        return "😞";
      case "disappointed":
        return "😟";
      case "scared":
        return "😨";
      case "angry":
        return "😡";
      default:
        return "😐";
    }
  }
}

class MoodUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveMoodUpdate(String mood, String note,
      {String? customEmoji}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('moodupdate').add({
        'userId': user.uid,
        'email': user.email,
        'mood': mood,
        'note': note,
        'moodEmoji': customEmoji ?? getMoodEmoji(mood),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  String getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case "happy":
        return "😊";
      case "sad":
        return "😞";
      case "disappointed":
        return "😟";
      case "scared":
        return "😨";
      case "angry":
        return "😡";
      default:
        return "😐";
    }
  }
}
