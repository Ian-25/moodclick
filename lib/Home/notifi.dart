import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:moodapp/Burgerbuttonfunc/appointment.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', whereIn: ['reaction', 'appointment'])
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    return const Stream.empty();
  }

  String getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String getFormattedDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today - show time only
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      // Yesterday - show 'Yesterday' and time
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      // Within a week - show day name and time
      return '${DateFormat('EEEE').format(date)} at ${DateFormat('h:mm a').format(date)}';
    } else {
      // More than a week ago - show full date and time
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    }
  }

  Future<String> _getUserNickname(String userId) async {
    if (userId.isEmpty) return 'User';
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('notifications').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? nickname = userData['reactingUserId'] as String?;
        if (nickname != null && nickname.isNotEmpty) {
          return nickname;
        }
      }
      return 'nickname';
    } catch (e) {
      return 'nickname';
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text(
                'Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _deleteNotification(notificationId);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color.fromARGB(255, 92, 17, 11)),
                ),
              ),
            ]);
      },
    );
  }

  void _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> data) {
    final type = data['type'] as String;
    final timestamp = data['timestamp'] as Timestamp?;

    if (type == 'reaction') {
      return _buildReactionNotification(data, timestamp);
    } else if (type == 'appointment') {
      return _buildAppointmentNotification(data, timestamp);
    }

    return const SizedBox.shrink();
  }

  Widget _buildReactionNotification(
      Map<String, dynamic> data, Timestamp? timestamp) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.favorite, color: Colors.white),
      ),
      title: Text('${data['reactorName']} reacted to your post'),
      subtitle: Text(getTimeAgo(timestamp)),
      onTap: () => _markAsRead(data['id']),
    );
  }

  Widget _buildAppointmentNotification(
      Map<String, dynamic> data, Timestamp? timestamp) {
    final status = data['status'] as String;
    final counselorName = data['counselorName'] as String;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(status),
        child: Icon(_getStatusIcon(status), color: Colors.white),
      ),
      title: Text('Appointment $status by $counselorName'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status == 'rescheduled') ...[
            Text('New date: ${_formatDate(data['rescheduledDate'])}'),
            Text('New time: ${data['rescheduledTime']}'),
          ],
          Text(getTimeAgo(timestamp)),
        ],
      ),
      onTap: () => _markAsRead(data['id']),
    );
  }

  void _showNotificationDetails(
      BuildContext context, Map<String, dynamic> data, String nickname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getNotificationIcon(data['type'] as String?),
                color: const Color.fromARGB(255, 243, 33, 33),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Notification Details',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getActionText(data['type'] as String?),
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time: ${getFormattedDateTime(data['timestamp'] as Timestamp?)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (data['message'] != null &&
                    data['message'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    data['message'].toString(),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            if (data['postId'] != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to the post
                  _navigateToPost(context, data['postId']);
                },
                child: const Text('View Post'),
              ),
          ],
        );
      },
    );
  }

  void _navigateToPost(BuildContext context, String postId) async {
    // TODO: Implement navigation to the specific post
    // You'll need to add your navigation logic here
  }

  void _viewAppointmentDetails(String? appointmentId) {
    // TODO: Implement the logic to view appointment details
    // For now, just print the appointmentId
    print('Viewing details for appointment: $appointmentId');
  }

  String _getActionText(String? type) {
    switch (type) {
      case 'like':
        return '';
      case 'reaction':
        return 'reacted to your post';
      default:
        return 'reacted to your post';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'reaction':
        return Icons.emoji_emotions;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        if (unreadCount == 0) return Container();

        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(
            minWidth: 16,
            minHeight: 16,
          ),
          child: Text(
            unreadCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  // Removed duplicate _buildAppointmentNotification method

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    return DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rescheduled':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rescheduled':
        return Icons.event_repeat;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTitle(String status, String counselorName) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Appointment Approved';
      case 'rescheduled':
        return 'Appointment Rescheduled';
      case 'cancelled':
        return 'Appointment Cancelled';
      default:
        return 'Appointment Update';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(253, 243, 33, 33),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data!.docs[index];
              final data = notification.data() as Map<String, dynamic>;
              // Add the document ID to the data map
              data['id'] = notification.id;
              final timestamp = data['timestamp'] as Timestamp?;

              return _buildNotificationItem(data);
            },
          );
        },
      ),
    );
  }
}

// Function of notification
Future<void> createNotification({
  required String postId,
  required String postOwnerId,
  required String triggerUserId,
  required String type,
  String? message,



}) async {
  try {
    // Get the trigger user's nickname
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(triggerUserId)
        .get();

    String nickname = 'User';
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      nickname = userData['nickname'] ?? 'User';
    }

    // Create the notification with precise server timestamp
    await FirebaseFirestore.instance.collection('notifications').add({
      'postId': postId,
      'postOwnerId': postOwnerId,
      'triggerUserId': triggerUserId,
      'triggerUserName': nickname,
      'type': type,
      'message': message,
      'timestamp':
          FieldValue.serverTimestamp(), // Uses server timestamp for accuracy
      'isRead': false,
      'createdAt': DateTime.now()
          .toUtc()
          .toIso8601String(), // Additional precise timestamp
    });
  } catch (e) {
    print('Error creating notification: $e');
  }
}

// Add this method to mark notifications as read
Future<void> markNotificationAsRead(String notificationId) async {
  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error marking notification as read: $e');
  }
}
