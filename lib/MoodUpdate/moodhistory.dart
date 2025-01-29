import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MoodHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('moodupdatehistory')
            .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              String moodEmoji =
                  data['moodEmoji'] ?? getMoodEmoji(data['mood']);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(moodEmoji),
                    backgroundColor: Colors.transparent,
                  ),
                  title: Row(
                    children: [
                      Text(
                        data['mood'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(moodEmoji),
                    ],
                  ),
                  subtitle: Text(
                    formatDateTime(date),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    data['note'] ?? '',
                    style: const TextStyle(fontStyle: FontStyle.italic),
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
      await _firestore.collection('moodupdatehistory').add({
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
