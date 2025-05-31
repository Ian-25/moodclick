import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppointmentNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen for appointment status changes
  Stream<QuerySnapshot> getAppointmentNotifications() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('appointments')
          .where('userId', isEqualTo: user.uid)
          .where('notificationSeen', isEqualTo: false)
          .snapshots();
    }
    return const Stream.empty();
  }

  // Create notification when appointment status changes
  Future<void> createAppointmentNotification({
    required String appointmentId,
    required String status,
    required String message,
    String? rescheduleReason,
    Timestamp? rescheduledDate,
    String? rescheduledTime,
    required String counselorName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Create notification
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'appointmentId': appointmentId,
        'type': 'appointment_$status',
        'status': status,
        'message': message,
        'counselorName': counselorName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'rescheduleDetails': status == 'rescheduled'
            ? {
                'reason': rescheduleReason,
                'newDate': rescheduledDate,
                'newTime': rescheduledTime,
              }
            : null,
      });

      // Update appointment notification status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'notificationSeen': false,
        'lastNotification': {
          'status': status,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print('Error creating appointment notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get notification badge count
  Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    }
    return Stream.value(0);
  }

  // Format notification message based on status
  String getNotificationMessage(String status, String counselorName) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Your appointment with $counselorName has been approved';
      case 'declined':
        return 'Your appointment with $counselorName has been declined';
      case 'rescheduled':
        return 'Your appointment with $counselorName has been rescheduled';
      default:
        return 'Your appointment status has been updated';
    }
  }

  // Get notification icon based on status
  IconData getNotificationIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'rescheduled':
        return Icons.event_repeat;
      default:
        return Icons.notifications;
    }
  }

  // Get notification color based on status
  Color getNotificationColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
