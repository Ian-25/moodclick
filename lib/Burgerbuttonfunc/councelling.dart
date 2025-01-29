import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodapp/messages/chat_page.dart';

class CounsellorsProfilePage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CounsellorsProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counsellors Profile Page'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('guidance_account').snapshots(),
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
              var counsellorData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counsellorData['username'] ?? 'No name',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Profession: ${counsellorData['profession'] ?? 'Not specified'}'),
                      Text(
                          'Experience: ${counsellorData['experience'] ?? 'Not specified'}'),
                      Text(
                          'Email: ${counsellorData['email'] ?? 'Not specified'}'),
                      Text(
                          'Contact: ${counsellorData['contact'] ?? 'Not specified'}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                counsellorName:
                                    counsellorData['username'] ?? '',
                                counsellorId: snapshot.data!.docs[index].id,
                              ),
                            ),
                          );
                        },
                        child: const Text('Contact Counsellor'),
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
}
