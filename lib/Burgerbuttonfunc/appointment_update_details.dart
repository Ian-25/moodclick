import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentUpdateDetails extends StatelessWidget {
  final String appointmentId;

  const AppointmentUpdateDetails({
    Key? key,
    required this.appointmentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Updates'),
        backgroundColor: const Color.fromARGB(255, 243, 33, 33),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointmentData =
              snapshot.data?.data() as Map<String, dynamic>?;

          if (appointmentData == null) {
            return const Center(child: Text('Appointment not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(appointmentData),
                const SizedBox(height: 20),
                if (appointmentData['status'] == 'rescheduled')
                  _buildRescheduleDetails(appointmentData),
                const SizedBox(height: 20),
                _buildUpdateHistory(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> appointmentData) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(appointmentData['status'] ?? ''),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                appointmentData['status'] ?? 'Unknown',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRescheduleDetails(Map<String, dynamic> appointmentData) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_repeat, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Rescheduling Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Reason:',
              appointmentData['rescheduleReason'] ?? 'No reason provided',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Previous Date:',
              _formatDate(appointmentData['date']),
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              'Previous Time:',
              appointmentData['time'] ?? 'Not specified',
            ),
            const Divider(),
            _buildDetailRow(
              'New Date:',
              _formatDate(appointmentData['rescheduledDate'] ??
                  appointmentData['date']),
              isHighlighted: true,
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              'New Time:',
              appointmentData['rescheduledTime'] ??
                  appointmentData['time'] ??
                  'Not specified',
              isHighlighted: true,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Rescheduled by:',
              appointmentData['rescheduledBy'] ?? 'Unknown',
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              'Rescheduled on:',
              _formatTimestamp(appointmentData['rescheduledAt'] as Timestamp?),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateHistory(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .collection('statusHistory')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reschedule available'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final historyData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return _buildHistoryItem(historyData);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> historyData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _getStatusColor(historyData['status'] ?? ''),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  historyData['status'] ?? 'Status Update',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(historyData['message'] ?? ''),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(historyData['timestamp'] as Timestamp?),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.blue : Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isHighlighted ? Colors.blue : Colors.black,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    if (date is Timestamp) {
      return DateFormat('EEEE, MMMM dd, yyyy').format(date.toDate());
    }
    return 'Invalid date';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
