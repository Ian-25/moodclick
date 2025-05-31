import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveUsersPage extends StatefulWidget {
  const ApproveUsersPage({super.key});

  @override
  _ApproveUsersPageState createState() => _ApproveUsersPageState();
}

class _ApproveUsersPageState extends State<ApproveUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Users'),
        backgroundColor: const Color.fromARGB(255, 243, 33, 33),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No users awaiting approval',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final user = snapshot.data!.docs[index];
              final data = user.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  title: Text(data['nickname'] ?? 'No nickname'),
                  subtitle: Text(data['email'] ?? 'No email'),
                  trailing: IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await _approveUser(user.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User approved successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
