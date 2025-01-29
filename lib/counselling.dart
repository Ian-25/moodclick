
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodapp/messages/chat_page.dart';

class CounsellingPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CounsellingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counselling'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('counsellors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> counsellor = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(counsellor['name'][0] ?? 'C'),
                  ),
                  title: Text(counsellor['name'] ?? 'Counsellor'),
                  subtitle: Text(counsellor['specialization'] ?? 'General Counselling'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            counsellorId: doc.id,
                            counsellorName: counsellor['name'] ?? 'Counsellor',
                          ),
                        ),
                      );
                    },
                    child: const Text('Contact'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
