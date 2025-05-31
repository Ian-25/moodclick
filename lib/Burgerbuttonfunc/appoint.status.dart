import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:moodapp/Burgerbuttonfunc/appointment_update_details.dart';
import 'package:moodapp/Services/appointment_notification_service.dart';

class AppointmentStatus extends StatefulWidget {
  const AppointmentStatus({super.key});

  @override
  State<AppointmentStatus> createState() => _AppointmentStatusState();
}

class _AppointmentStatusState extends State<AppointmentStatus> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppointmentNotificationService _notificationService =
      AppointmentNotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Status'),
        backgroundColor: const Color.fromARGB(255, 243, 33, 33),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('appointments')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .orderBy('createdAt', descending: true)
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
                'No appointments found',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final appointment = snapshot.data!.docs[index];
              final data = appointment.data() as Map<String, dynamic>;

              // Updated counselor name retrieval
              final String counselor = data['counselorName'] ??
                  data['counselorDetails']?['displayName'] ??
                  data['counselor'] ??
                  'Not specified';

              final DateTime createdAt =
                  (data['createdAt'] as Timestamp).toDate();
              final DateTime appointmentDate =
                  (data['date'] as Timestamp).toDate();
              final String time = data['time'] ?? 'Not specified';
              final String reason = data['reason'] ?? 'Not specified';
              final String status = data['status'] ?? 'Pending';
              final String userEmail = data['userEmail'] ?? '';

              _listenToAppointmentChanges(appointment.id, counselor);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Counseling Appointment with $counselor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created on ${DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(appointmentDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time: $time',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: $reason',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'update') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentUpdateDetails(
                              appointmentId: appointment.id,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        await _deleteAppointment(appointment.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'update',
                        child: Row(
                          children: [
                            Icon(Icons.update, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('View Updates'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color.fromARGB(255, 9, 233, 42);
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Appointment'),
        content:
            const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      try {
        await _firestore.collection('appointments').doc(appointmentId).delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted successfully'),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppointmentHistory(String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appointment History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('appointments')
                      .doc(appointmentId)
                      .snapshots(),
                  builder: (context, appointmentSnapshot) {
                    if (appointmentSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${appointmentSnapshot.error}'));
                    }

                    if (appointmentSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final appointmentData = appointmentSnapshot.data?.data()
                        as Map<String, dynamic>?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show rescheduling information if available
                        if (appointmentData?['status'] == 'rescheduled')
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rescheduling Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: ${appointmentData?['rescheduleReason'] ?? 'No reason provided'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'New Date: ${_formatDate(appointmentData?['rescheduledDate'])}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'New Time: ${appointmentData?['rescheduledTime'] ?? 'Not specified'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Rescheduled by: ${appointmentData?['rescheduledBy'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),

                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('appointments')
                                .doc(appointmentId)
                                .collection('statusHistory')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, historySnapshot) {
                              if (historySnapshot.hasError) {
                                return Center(
                                    child: Text(
                                        'Error: ${historySnapshot.error}'));
                              }

                              if (!historySnapshot.hasData ||
                                  historySnapshot.data!.docs.isEmpty) {
                                return const Center(
                                    child: Text('No history available'));
                              }

                              return ListView.builder(
                                itemCount: historySnapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final historyData =
                                      historySnapshot.data!.docs[index].data()
                                          as Map<String, dynamic>;
                                  final DateTime timestamp =
                                      (historyData['timestamp'] as Timestamp)
                                          .toDate();
                                  final String status =
                                      historyData['status'] ?? '';
                                  final String message =
                                      historyData['message'] ?? '';

                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        status,
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(message),
                                          Text(
                                            DateFormat('MMM dd, yyyy - hh:mm a')
                                                .format(timestamp),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
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
                        ),
                      ],
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    }
    return 'Invalid date';
  }

  void _listenToAppointmentChanges(String appointmentId, String counselorName) {
    _firestore
        .collection('appointments')
        .doc(appointmentId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final String status = data['status'] ?? '';
      final bool notificationSeen = data['notificationSeen'] ?? true;

      if (!notificationSeen) {
        _notificationService.createAppointmentNotification(
          appointmentId: appointmentId,
          status: status,
          message: _notificationService.getNotificationMessage(
              status, counselorName),
          rescheduleReason: data['rescheduleReason'],
          rescheduledDate: data['rescheduledDate'],
          rescheduledTime: data['rescheduledTime'],
          counselorName: counselorName,
        );
      }
    });
  }
}
